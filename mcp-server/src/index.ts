#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { resolve, join, dirname } from "path";
import { writeFileSync, mkdirSync, readFileSync, existsSync } from "fs";
import { fileURLToPath } from "url";
import { tmpdir } from "os";
import { z } from "zod";
import { resolveCSS } from "./css-resolver.js";
import { resolveTextSearch } from "./text-search-resolver.js";
import { SwiftDialogProvider } from "./providers/swift.js";
import { WindowsDialogProvider } from "./providers/windows.js";
import type { DialogProvider } from "./providers/interface.js";
import type { DialogPosition, QuestionsMode, TweakParameter, SketchBlock, SketchLayoutNode } from "./types.js";
import { compactResponse } from "./compact.js";
import { humanize } from "./humanize.js";
import { readSettings } from "./settings.js";
import { checkForUpdate } from "./update-check.js";
import { validateNoAllOfAbove } from "./validate-choices.js";

const DIALOG_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes
const HEARTBEAT_INTERVAL_MS = 15_000;

const AFK_MESSAGE =
  "The user has enabled Away (AFK) mode in Consult User MCP, so no dialog will be shown. " +
  "Proceed autonomously with a reasonable default and note the open question in your final response. " +
  "Do not fall back to other interactive question tools.";

function afkResponse() {
  return {
    content: [{ type: "text" as const, text: AFK_MESSAGE }],
    structuredContent: { afk: true },
  };
}

/** Unescape literal \n and \t that LLMs commonly embed in text instead of actual newlines/tabs. */
function unescLiterals(s: string): string {
  return s.replace(/\\n/g, "\n").replace(/\\t/g, "\t");
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error(`Dialog timed out after ${ms / 1000}s`)), ms)
    ),
  ]);
}

function withHeartbeat<T>(
  promise: Promise<T>,
  extra: { _meta?: { progressToken?: string | number }; sendNotification: (n: never) => Promise<void> },
): Promise<T> {
  const token = extra._meta?.progressToken;
  if (token == null) return promise;
  let progress = 0;
  const iv = setInterval(() => {
    extra.sendNotification({
      method: "notifications/progress" as const,
      params: { progressToken: token, progress: ++progress, message: "Waiting for user response" },
    } as never);
  }, HEARTBEAT_INTERVAL_MS);
  return promise.finally(() => clearInterval(iv));
}

/** Wrap a provider call with timeout + heartbeat. */
function tracked<T>(promise: Promise<T>, extra: Parameters<typeof withHeartbeat>[1]): Promise<T> {
  return withHeartbeat(withTimeout(promise, DIALOG_TIMEOUT_MS), extra);
}

// Load the base prompt (usage instructions for ask/notify/tweak) so it can be
// exposed via the MCP protocol `instructions` field. Single source of truth is
// macos-app/Sources/Resources/base-prompt.md; the app bundle copies it to
// Contents/Resources/base-prompt.md. Search both layouts; omit if not found.
// Global ~/.claude/CLAUDE.md just records the file path as a marker —
// the actual content is delivered here, per-session, over the protocol.
function loadBasePrompt(): string | undefined {
  const here = dirname(fileURLToPath(import.meta.url)); // .../mcp-server/dist
  const candidates = [
    join(here, "..", "..", "macos-app", "Sources", "Resources", "base-prompt.md"), // dev/repo
    join(here, "..", "..", "base-prompt.md"),                                       // app bundle Resources/ (.../mcp-server/dist -> Resources/)
  ];
  const path = candidates.find(existsSync);
  return path ? readFileSync(path, "utf8") : undefined;
}

const server = new McpServer(
  { name: "consult-user-mcp-server", version: "1.0.0" },
  { instructions: loadBasePrompt() },
);
function createProvider(): DialogProvider {
  if (process.platform === "win32") return new WindowsDialogProvider();
  return new SwiftDialogProvider();
}

const provider = createProvider();

let cachedProjectPath: string | undefined;

const questionSchema = z.object({
  id: z.string().min(1).max(50)
    .describe("Stable key for this question; the form answer is keyed by it."),
  question: z.string().min(1).max(500)
    .describe("The question text shown to the user."),
  type: z.enum(["choice", "text"]).default("choice")
    .describe("choice = pick from options, text = free-form input."),
  options: z.array(z.string().min(1).max(100)).min(2).max(10).optional()
    .describe("Choices to pick from. Required (min 2) when type=choice."),
  descriptions: z.array(z.string().max(200)).optional()
    .describe("Optional per-option descriptions, index-aligned with options."),
  multi: z.boolean().default(false)
    .describe("Allow selecting multiple options (choice only); answer becomes string[]."),
  other: z.boolean().default(true)
    .describe("Include an 'Other' option so the user can type a custom answer (returned as the answer value, never the literal 'Other'). Set false only for closed-ended lists."),
  placeholder: z.string().max(200).optional()
    .describe("Placeholder text for text questions."),
  hidden: z.boolean().default(false)
    .describe("Mask input like a password field (text only)."),
}).superRefine((data, ctx) => {
  if (data.type === "choice" && (!data.options || data.options.length < 2)) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "options required (min 2) for choice questions",
      path: ["options"],
    });
  }
});

const askSchema = z.object({
  type: z.enum(["confirm", "pick", "text", "form"])
    .describe("Dialog type: confirm (yes/no), pick (select from list), text (free input), form (multi-question wizard — use it to batch 2+ questions)."),
  body: z.string().min(1).max(1000)
    .describe("The question or message shown to the user. Supports markdown."),
  // confirm
  yes: z.string().max(20).default("Yes")
    .describe("Confirm-button label (confirm only)."),
  no: z.string().max(20).default("No")
    .describe("Decline-button label (confirm only)."),
  // pick
  choices: z.array(z.string().min(1).max(100)).min(2).max(20).optional()
    .describe("Options to pick from. Required (min 2) when type=pick."),
  multi: z.boolean().default(false)
    .describe("Allow selecting multiple choices (pick only); answer becomes string[]."),
  other: z.boolean().default(true)
    .describe("Include an 'Other' option so the user can type a custom answer (returned as the answer value, never the literal 'Other'). Set false only for closed-ended lists (pick only)."),
  descriptions: z.array(z.string().max(200)).optional()
    .describe("Optional per-choice descriptions, index-aligned with choices (pick only)."),
  default: z.string().optional()
    .describe("Preselected choice (pick) or prefilled text (text)."),
  // text
  hidden: z.boolean().default(false)
    .describe("Mask input like a password field (text only)."),
  // form
  questions: z.array(questionSchema).min(1).max(10).optional()
    .describe("Questions for the step-by-step wizard. Required when type=form."),
  // shared
  title: z.string().max(80).optional()
    .describe("Dialog title. The client name is prefixed automatically."),
  position: z.enum(["left", "right", "center"]).optional()
    .describe("Screen position of the dialog."),
  project_path: z.string().optional()
    .describe("Absolute project path, shown as a badge. Cached for the session after the first call — later calls may omit it."),
});

// Response-state fields shared by every interactive dialog. At most one
// special state appears per response (priority: snoozed > askDifferently >
// feedbackText > cancelled); feedback can travel alongside a normal answer.
const responseStateFields = {
  snoozed: z.boolean().optional()
    .describe("User snoozed the dialog. Sleep remainingSeconds, then re-ask the exact same question. Do not proceed or ask something else."),
  remainingSeconds: z.number().optional()
    .describe("Seconds until the snooze expires."),
  askDifferently: z.string().optional()
    .describe("Re-ask the same question as this dialog type: confirm, pick, pick-multi, text, text-hidden, or form-wizard. Do not skip or change topic."),
  feedbackText: z.string().optional()
    .describe("Note from the user that travels alongside the answer. Accept the answer and incorporate the note; do not re-ask."),
  cancelled: z.boolean().optional()
    .describe("User dismissed the dialog. Proceed with a reasonable default."),
  afk: z.boolean().optional()
    .describe("Away mode is on; no dialog was shown. Proceed autonomously with reasonable defaults."),
};

const askOutputSchema = z.object({
  answer: z.union([
    z.boolean(),
    z.string(),
    z.array(z.string()),
    z.record(z.union([z.string(), z.array(z.string())])),
  ]).optional()
    .describe("The user's answer: boolean (confirm), string (pick/text — a custom 'Other' answer arrives here as typed), string[] (pick multi), or question-id → answer map (form)."),
  completedCount: z.number().optional()
    .describe("Form only: number of questions answered."),
  feedbackByQuestion: z.record(z.string()).optional()
    .describe("Form only: per-question notes keyed by question id, annotating the corresponding answers."),
  ...responseStateFields,
});

server.registerTool("ask", {
  title: "Ask the user",
  description: "Interactive dialog. Types: confirm (yes/no), pick (select from list), text (free input), form (multi-question). 10min timeout. If snoozed: sleep remainingSeconds, retry.",
  inputSchema: askSchema,
  outputSchema: askOutputSchema,
  annotations: { readOnlyHint: true, openWorldHint: false },
}, async (p, extra) => {
  provider.pulse();

  if (p.project_path) cachedProjectPath = p.project_path;
  if (readSettings().afkMode) return afkResponse();

  const projectPath = p.project_path ?? cachedProjectPath ?? "";
  const position = p.position as DialogPosition | undefined;

  let raw: unknown;
  const body = unescLiterals(p.body);

  switch (p.type) {
    case "confirm":
      raw = await tracked(provider.confirm({
        body, title: p.title ?? "Confirmation",
        confirmLabel: p.yes, cancelLabel: p.no,
        position, projectPath,
      }), extra);
      break;

    case "pick":
      if (!p.choices?.length) throw new Error("choices required for type=pick");
      validateNoAllOfAbove(p.choices);
      raw = await tracked(provider.choose({
        body, title: p.title, choices: p.choices, descriptions: p.descriptions,
        allowMultiple: p.multi, allowOther: p.other, defaultSelection: p.default,
        position, projectPath,
      }), extra);
      break;

    case "text":
      raw = await tracked(provider.textInput({
        body, title: p.title ?? "Input",
        defaultValue: p.default ?? "", hidden: p.hidden,
        position, projectPath,
      }), extra);
      break;

    case "form": {
      if (!p.questions?.length) throw new Error("questions required for type=form");
      for (const q of p.questions) {
        if (q.type === "choice" && q.options) validateNoAllOfAbove(q.options);
      }
      raw = await tracked(provider.questions({
        body, title: p.title,
        questions: p.questions.map(q => ({
          id: q.id, question: unescLiterals(q.question),
          type: q.type,
          options: (q.options ?? []).map((label, i) => ({ label, description: q.descriptions?.[i] })),
          multiSelect: q.multi,
          allowOther: q.type === "choice" ? q.other : undefined,
          placeholder: q.placeholder,
          hidden: q.hidden,
        })),
        mode: "wizard" satisfies QuestionsMode,
        position, projectPath,
      }), extra);
      break;
    }
  }

  const compact = compactResponse(p.type, raw);
  const { humanizeResponses, reviewBeforeSend } = readSettings();
  const result = humanizeResponses ? humanize(compact) : compact;
  const text = typeof result === "string" ? result : JSON.stringify(result);

  if (reviewBeforeSend && !compact.snoozed) {
    await provider.preview({ body: text }).catch(() => {});
  }

  return { content: [{ type: "text", text }], structuredContent: compact };
});

/** Convert label to kebab-case id: "Font Size" → "font-size", "Line Height (px)" → "line-height-px" */
function toKebabCase(label: string): string {
  return label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

const tweakParameterSchema = z.object({
  id: z.string().min(1).max(50).optional()
    .describe("Stable key in the response answer map. Auto-derived from label as kebab-case if omitted."),
  label: z.string().min(1).max(100)
    .describe("Human-readable slider label, e.g. \"Font Size\"."),
  element: z.string().max(100).optional()
    .describe("Optional element/selector hint shown under the label."),
  file: z.string().min(1)
    .describe("File to edit, relative to project_path (or absolute)."),
  // CSS reference (resolved by server)
  selector: z.string().max(200).optional()
    .describe("CSS selector for the rule to edit (CSS format, together with property). Auto-resolves line/column/expectedText/current/unit."),
  property: z.string().max(100).optional()
    .describe("CSS property name within the selector's rule (CSS format)."),
  index: z.number().int().min(0).optional()
    .describe("Zero-based value index for multi-value CSS properties like `margin: 10px 20px` (CSS format)."),
  fn: z.string().max(50).optional()
    .describe("CSS function whose argument to target, e.g. `rotateY` in a transform (CSS format)."),
  // Text search (resolved by server)
  search: z.string().max(500).optional()
    .describe("Pattern with a single `{v}` placeholder marking the numeric value to capture (e.g. `filter: blur({v}px)`, `padding: {v}rem`). When two parameters share the same pattern in the same file, `current` disambiguates by value."),
  // Direct location (or filled by resolver)
  line: z.number().int().min(1).optional()
    .describe("1-based line number of the value (direct format)."),
  column: z.number().int().min(1).optional()
    .describe("1-based column where the numeric value starts (direct format)."),
  expectedText: z.string().min(1).max(50).optional()
    .describe("Exact text expected at line/column, used as a safety check before writing (direct format)."),
  current: z.number().optional()
    .describe("The numeric value currently in the file at the matched location. Required when `search` is set: must equal the actual file value (used to disambiguate when multiple matches exist) and to seed the slider."),
  // Range
  min: z.number().describe("Slider minimum."),
  max: z.number().describe("Slider maximum."),
  step: z.number().positive().optional().describe("Slider step size."),
  unit: z.string().max(10).optional().describe("Display unit, e.g. \"px\" or \"rem\". Auto-detected for CSS/search formats."),
}).refine(
  (p) =>
    (p.selector && p.property)
    || (p.line != null && p.column != null && p.expectedText && p.current != null)
    || (p.search && p.current != null),
  { message: "Provide selector+property (CSS), search+current (text search), or line+column+expectedText+current (direct)" },
);

const tweakSchema = z.object({
  body: z.string().min(1).max(1000)
    .describe("Message explaining what is being tuned. Supports markdown."),
  parameters: z.array(tweakParameterSchema).min(1).max(20)
    .describe("One slider per parameter. Each uses one of three formats: text search (search+current), CSS reference (selector+property), or direct (line+column+expectedText+current)."),
  title: z.string().max(80).optional()
    .describe("Pane title. The client name is prefixed automatically."),
  position: z.enum(["left", "right", "center"]).optional()
    .describe("Screen position of the pane."),
  project_path: z.string().optional()
    .describe("Absolute project path; relative parameter files resolve against it. Cached for the session after the first call."),
});

const tweakOutputSchema = z.object({
  answer: z.record(z.number()).optional()
    .describe("Final values keyed by parameter id."),
  action: z.enum(["file", "agent"]).optional()
    .describe("file = values already written to disk, nothing to do; agent = files reverted, apply the returned values yourself."),
  replayAnimations: z.boolean().optional()
    .describe("A CSS animation replay client was connected during the session."),
  ...responseStateFields,
});

server.registerTool("tweak", {
  title: "Tweak values live",
  outputSchema: tweakOutputSchema,
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  description: "Value tweak pane. Opens an always-on-top slider panel for real-time numeric value adjustment with live file writes. User completes via \"Save to File\" (keeps file writes, action:\"file\") or \"Tell Agent\" (reverts files, returns desired values for you to apply, action:\"agent\"). When using `search`: pattern must contain a single `{v}` placeholder (e.g. `padding: {v}px`); `current` must equal the actual file value and is used to pick the right occurrence when the pattern matches multiple lines. 10min timeout. If snoozed: sleep remainingSeconds, retry.",
  inputSchema: tweakSchema,
}, async (p, extra) => {
  provider.pulse();

  if (p.project_path) cachedProjectPath = p.project_path;
  if (readSettings().afkMode) return afkResponse();

  const projectPath = p.project_path ?? cachedProjectPath ?? "";
  const position = p.position as DialogPosition | undefined;
  const body = unescLiterals(p.body);

  // Resolve parameters: auto-derive ids, resolve CSS/search to direct locations
  const parameters = p.parameters.map((param) => {
    const id = param.id ?? toKebabCase(param.label);

    if (param.selector && param.property) {
      const filePath = resolve(projectPath, param.file);
      const result = resolveCSS(filePath, param.selector, param.property, {
        index: param.index,
        fn: param.fn,
      });
      return {
        ...param, id,
        line: result.line, column: result.column,
        expectedText: result.expectedText, current: result.current,
        unit: param.unit ?? result.unit,
        element: param.element ?? param.selector,
      };
    }

    if (param.search) {
      const filePath = resolve(projectPath, param.file);
      const result = resolveTextSearch(filePath, param.search, { current: param.current });
      return {
        ...param, id,
        line: result.line, column: result.column,
        expectedText: result.expectedText, current: result.current,
        unit: param.unit ?? result.unit,
      };
    }

    return { ...param, id };
  }) as TweakParameter[];

  const ids = parameters.map((p) => p.id);
  const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
  if (dupes.length) throw new Error(`Duplicate parameter ids: ${[...new Set(dupes)].join(", ")}`);

  // Defensive: catch parameters that resolved to the same file location.
  // Covers genuinely-ambiguous search collisions and accidental direct-coord duplication.
  const locationOwners = new Map<string, string>();
  for (const param of parameters) {
    if (param.line == null || param.column == null) continue;
    const key = `${param.file}:${param.line}:${param.column}`;
    const prev = locationOwners.get(key);
    if (prev) {
      throw new Error(
        `Parameters "${prev}" and "${param.id}" resolved to the same location ${key}. ` +
        `Make their 'search' patterns more specific or pass distinct line+column+expectedText directly.`
      );
    }
    locationOwners.set(key, param.id);
  }

  const raw = await tracked(provider.tweak({
    body,
    parameters,
    title: p.title,
    position,
    projectPath,
  }), extra);

  const compact = compactResponse("tweak", raw);
  const { humanizeResponses, reviewBeforeSend } = readSettings();
  const result = humanizeResponses ? humanize(compact) : compact;
  const text = typeof result === "string" ? result : JSON.stringify(result);

  if (reviewBeforeSend && !compact.snoozed) {
    await provider.preview({ body: text }).catch(() => {});
  }

  return { content: [{ type: "text", text }], structuredContent: compact };
});

server.registerTool("notify", {
  title: "Notify the user",
  outputSchema: z.object({
    success: z.boolean().describe("Whether the notification was displayed."),
  }),
  annotations: { readOnlyHint: true, openWorldHint: false },
  description: "Non-blocking notification. Returns {success}.",
  inputSchema: z.object({
    body: z.string().min(1).max(1000)
      .describe("Notification message shown to the user."),
    title: z.string().max(80).default("Notice")
      .describe("Notification title. The client name is prefixed automatically."),
    sound: z.boolean().default(true)
      .describe("Play a notification sound."),
    project_path: z.string().optional()
      .describe("Absolute project path, shown as a badge. Cached for the session after the first call."),
  }),
}, async (p) => {
  provider.pulse();
  if (p.project_path) cachedProjectPath = p.project_path;
  const projectPath = p.project_path ?? cachedProjectPath;
  const r = await provider.notify({ body: unescLiterals(p.body), title: p.title, sound: p.sound, projectPath });
  return {
    content: [{ type: "text", text: JSON.stringify({ success: r.success }) }],
    structuredContent: { success: r.success },
  };
});

function isHeadless(): boolean {
  const env = process.env;
  return !!(env.SSH_CONNECTION || env.SSH_TTY || env.CI);
}

function formatSketchBlock(b: SketchBlock): string {
  return `  - "${b.label}" at (${b.x},${b.y}) size ${b.w}×${b.h}`;
}

const blockSchema = z.object({
  label: z.string().min(1).max(50),
  x: z.number().int().min(0),
  y: z.number().int().min(0),
  w: z.number().int().min(1),
  h: z.number().int().min(1),
  color: z.string().max(20).optional(),
  content: z.enum(["text", "image", "video", "avatar", "button", "input", "list", "chart", "map", "nav", "form"]).optional()
    .describe("Wireframe content type. Auto-inferred from label if omitted."),
  role: z.enum(["header", "sidebar", "canvas", "footer", "toolbar", "panel"]).optional()
    .describe("Semantic role. Adds faint background tint to the block zone."),
  flowDirection: z.enum(["row", "column"]).optional()
    .describe("Flow direction arrow shown next to block number."),
  importance: z.enum(["primary", "secondary", "tertiary"]).optional()
    .describe("Visual importance hierarchy. Auto-inferred from role if omitted."),
  elevation: z.number().int().min(0).max(3).optional()
    .describe("Shadow elevation level (0-3). Auto-inferred from label if omitted."),
});

const dimensionValue = z.union([
  z.number().int().min(1),
  z.enum(["hug", "fill"]),
]);

const layoutNodeSchema: z.ZodType = z.lazy(() =>
  z.object({
    id: z.string().min(1).max(50),
    role: z.enum(["header", "sidebar", "canvas", "footer", "toolbar", "panel"]).optional(),
    label: z.string().max(50).optional(),
    children: z.array(layoutNodeSchema).optional(),
    constraints: z.object({
      width: dimensionValue.optional(),
      height: dimensionValue.optional(),
    }).optional(),
    layout: z.object({
      direction: z.enum(["row", "column"]).optional(),
      gap: z.number().int().min(0).max(10).optional(),
    }).optional(),
    priority: z.number().int().min(0).optional(),
    color: z.string().max(20).optional(),
  })
);

let proposeLayoutActive = false;

const layoutOutputSchema = z.object({
  status: z.enum(["accepted", "modified", "cancelled"]).optional()
    .describe("accepted = layout kept as proposed; modified = user changed it (see changes/layout); cancelled = no layout."),
  summary: z.string().optional(),
  changes: z.array(z.string()).optional()
    .describe("Human-readable list of the user's modifications."),
  layout: z.object({
    columns: z.number(),
    rows: z.number(),
    blocks: z.array(z.object({
      label: z.string(),
      x: z.number(),
      y: z.number(),
      w: z.number(),
      h: z.number(),
    }).passthrough()),
  }).passthrough().optional()
    .describe("Final grid layout with block positions and sizes."),
  imagePath: z.string().optional()
    .describe("Path to an SVG rendering of the final layout."),
  afk: z.boolean().optional()
    .describe("Away mode is on; no editor was shown. Proceed autonomously."),
});

server.registerTool("propose_layout", {
  title: "Propose a layout",
  outputSchema: layoutOutputSchema,
  annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  description: "Open interactive grid layout editor. Accepts either explicit grid blocks or a semantic structure tree (direction/constraints-based). User can drag/resize/add/remove blocks. Returns structured layout data + ASCII + SVG. 10 min timeout. macOS only.",
  inputSchema: z.object({
    width: z.number().int().min(3).max(20).default(12).describe("Grid columns (3-20)"),
    height: z.number().int().min(3).max(20).default(8).describe("Grid rows (3-20)"),
    template: z.enum(["compact", "standard", "spacious", "detailed", "mobile"]).optional()
      .describe("Preset template (overrides width/height)"),
    title: z.string().max(80).default("Layout Sketch").describe("Dialog title"),
    description: z.string().max(200).optional().describe("Description shown in dialog"),
    blocks: z.array(blockSchema).default([]).describe("Initial blocks with grid coordinates (alternative to structure)"),
    structure: layoutNodeSchema.optional().describe("Semantic layout tree with direction/constraints (alternative to blocks)"),
    frame: z.enum(["browser", "phone", "tablet"]).optional()
      .describe("Device frame chrome wrapping the canvas. Mobile template auto-sets 'phone'."),
    annotations: z.array(z.object({
      x: z.number().int().min(0),
      y: z.number().int().min(0),
      text: z.string().min(1).max(100),
    })).optional().describe("Numbered callout markers at grid coordinates with legend text."),
    project_path: z.string().optional(),
  }),
}, async (p, extra) => {
  if (isHeadless()) {
    throw new Error("Interactive layout editor requires a desktop environment (unavailable over SSH/CI)");
  }
  if (proposeLayoutActive) {
    throw new Error("An interactive layout session is already running. Complete or cancel it first.");
  }
  if (p.project_path) cachedProjectPath = p.project_path;
  if (readSettings().afkMode) return afkResponse();

  proposeLayoutActive = true;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), DIALOG_TIMEOUT_MS);
  try {
    const r = await withHeartbeat(provider.proposeLayout({
      width: p.width,
      height: p.height,
      template: p.template,
      title: p.title,
      description: p.description,
      blocks: p.blocks,
      structure: p.structure as SketchLayoutNode,
      frame: p.frame,
      annotations: p.annotations,
    }, controller.signal), extra);

    const lines: string[] = [`Status: ${r.status}`];
    if (r.summary) lines.push("", r.summary);
    if (r.changes?.length) {
      lines.push("", "Changes:");
      for (const c of r.changes) lines.push(`  - ${c}`);
    }
    if (r.layout?.blocks?.length) {
      lines.push("", `Grid: ${r.layout.columns}×${r.layout.rows}`, "Blocks:");
      for (const b of r.layout.blocks) lines.push(formatSketchBlock(b));
    }
    if (r.ascii) lines.push("", "ASCII:", r.ascii);

    const content: { type: "text"; text: string }[] = [{ type: "text", text: lines.join("\n") }];

    const structured: Record<string, unknown> = { status: r.status };
    if (r.summary) structured.summary = r.summary;
    if (r.changes?.length) structured.changes = r.changes;
    if (r.layout) structured.layout = r.layout;

    if (r.image) {
      const dir = join(tmpdir(), "consult-user-sketch");
      mkdirSync(dir, { recursive: true });
      const svgPath = join(dir, `layout-${Date.now()}.svg`);
      writeFileSync(svgPath, r.image);
      content.push({ type: "text", text: `\nImage: ${svgPath}` });
      structured.imagePath = svgPath;
    }

    return { content, structuredContent: structured };
  } finally {
    clearTimeout(timeout);
    proposeLayoutActive = false;
  }
});

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  provider.setClientName(server.server.getClientVersion()?.name ?? "MCP");
  console.error("Consult User MCP Server running on stdio");

  checkForUpdate()
    .then(async (result) => {
      if (result) {
        await provider.notify({
          body: `v${result.remoteVersion} is available (you have v${result.currentVersion}). Right-click tray icon → Check for Updates.`,
          title: "Update Available",
          sound: false,
        });
      }
    })
    .catch(() => {});
}

main().catch((e) => { console.error("Server error:", e); process.exit(1); });
