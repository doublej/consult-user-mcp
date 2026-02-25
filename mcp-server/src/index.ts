import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { resolve } from "path";
import { z } from "zod";
import { resolveCSS } from "./css-resolver.js";
import { resolveTextSearch } from "./text-search-resolver.js";
import { SwiftDialogProvider } from "./providers/swift.js";
import { WindowsDialogProvider } from "./providers/windows.js";
import type { DialogProvider } from "./providers/interface.js";
import type { DialogPosition, QuestionsMode, TweakParameter } from "./types.js";
import { compactResponse } from "./compact.js";
import { humanize } from "./humanize.js";
import { readSettings } from "./settings.js";
import { checkForUpdate } from "./update-check.js";
import { validateNoAllOfAbove } from "./validate-choices.js";

const DIALOG_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes
const HEARTBEAT_INTERVAL_MS = 15_000;

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

const server = new McpServer({ name: "consult-user-mcp-server", version: "1.0.0" });
function createProvider(): DialogProvider {
  if (process.platform === "win32") return new WindowsDialogProvider();
  return new SwiftDialogProvider();
}

const provider = createProvider();

let cachedProjectPath: string | undefined;

const questionSchema = z.object({
  id: z.string().min(1).max(50),
  question: z.string().min(1).max(500),
  type: z.enum(["choice", "text"]).default("choice"),
  options: z.array(z.string().min(1).max(100)).min(2).max(10).optional(),
  descriptions: z.array(z.string().max(200)).optional(),
  multi: z.boolean().default(false),
  placeholder: z.string().max(200).optional(),
  hidden: z.boolean().default(false),
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
  type: z.enum(["confirm", "pick", "text", "form"]),
  body: z.string().min(1).max(1000),
  // confirm
  yes: z.string().max(20).default("Yes"),
  no: z.string().max(20).default("No"),
  // pick
  choices: z.array(z.string().min(1).max(100)).min(2).max(20).optional(),
  multi: z.boolean().default(false),
  descriptions: z.array(z.string().max(200)).optional(),
  default: z.string().optional(),
  // text
  hidden: z.boolean().default(false),
  // form
  questions: z.array(questionSchema).min(1).max(10).optional(),
  mode: z.enum(["wizard", "accordion"]).default("wizard"),
  // shared
  title: z.string().max(80).optional(),
  position: z.enum(["left", "right", "center"]).default("left"),
  project_path: z.string().optional(),
});

server.registerTool("ask", {
  description: "Interactive dialog. Types: confirm (yes/no), pick (select from list), text (free input), form (multi-question). 10min timeout. If snoozed: sleep remainingSeconds, retry.",
  inputSchema: askSchema,
}, async (p, extra) => {
  provider.pulse();

  if (p.project_path) cachedProjectPath = p.project_path;
  const projectPath = p.project_path ?? cachedProjectPath ?? "";
  const position = p.position as DialogPosition;

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
        allowMultiple: p.multi, defaultSelection: p.default,
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
          placeholder: q.placeholder,
          hidden: q.hidden,
        })),
        mode: p.mode as QuestionsMode,
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

  return { content: [{ type: "text", text }] };
});

/** Convert label to kebab-case id: "Font Size" → "font-size", "Line Height (px)" → "line-height-px" */
function toKebabCase(label: string): string {
  return label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

const tweakParameterSchema = z.object({
  id: z.string().min(1).max(50).optional(),
  label: z.string().min(1).max(100),
  element: z.string().max(100).optional(),
  file: z.string().min(1),
  // CSS reference (resolved by server)
  selector: z.string().max(200).optional(),
  property: z.string().max(100).optional(),
  index: z.number().int().min(0).optional(),
  fn: z.string().max(50).optional(),
  // Text search (resolved by server)
  search: z.string().max(500).optional(),
  // Direct location (or filled by resolver)
  line: z.number().int().min(1).optional(),
  column: z.number().int().min(1).optional(),
  expectedText: z.string().min(1).max(50).optional(),
  current: z.number().optional(),
  // Range
  min: z.number(),
  max: z.number(),
  step: z.number().positive().optional(),
  unit: z.string().max(10).optional(),
}).refine(
  (p) => (p.selector && p.property) || (p.line != null && p.column != null && p.expectedText && p.current != null) || p.search,
  { message: "Provide selector+property (CSS), search (text search), or line+column+expectedText+current (direct)" },
);

const tweakSchema = z.object({
  body: z.string().min(1).max(1000),
  parameters: z.array(tweakParameterSchema).min(1).max(20),
  title: z.string().max(80).optional(),
  position: z.enum(["left", "right", "center"]).default("left"),
  project_path: z.string().optional(),
});

server.registerTool("tweak", {
  description: "Value tweak pane. Opens an always-on-top slider panel for real-time numeric value adjustment with live file writes. User completes via \"Save to File\" (keeps file writes, action:\"file\") or \"Tell Agent\" (reverts files, returns desired values for you to apply, action:\"agent\"). 10min timeout. If snoozed: sleep remainingSeconds, retry.",
  inputSchema: tweakSchema,
}, async (p, extra) => {
  provider.pulse();

  if (p.project_path) cachedProjectPath = p.project_path;
  const projectPath = p.project_path ?? cachedProjectPath ?? "";
  const position = p.position as DialogPosition;
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
      const result = resolveTextSearch(filePath, param.search);
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

  return { content: [{ type: "text", text }] };
});

server.registerTool("notify", {
  description: "Non-blocking notification. Returns {success}.",
  inputSchema: z.object({
    body: z.string().min(1).max(1000),
    title: z.string().max(80).default("Notice"),
    sound: z.boolean().default(true),
    project_path: z.string().optional(),
  }),
}, async (p) => {
  provider.pulse();
  if (p.project_path) cachedProjectPath = p.project_path;
  const projectPath = p.project_path ?? cachedProjectPath;
  const r = await provider.notify({ body: unescLiterals(p.body), title: p.title, sound: p.sound, projectPath });
  return { content: [{ type: "text", text: JSON.stringify({ success: r.success }) }] };
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
