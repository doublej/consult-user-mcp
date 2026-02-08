import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { SwiftDialogProvider } from "./providers/swift.js";
import type { DialogPosition, QuestionsMode } from "./types.js";
import { compactResponse } from "./compact.js";
import { checkForUpdate } from "./update-check.js";

const DIALOG_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes
const HEARTBEAT_INTERVAL_MS = 15_000;

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
const provider = new SwiftDialogProvider();

let cachedProjectPath: string | undefined;

const questionSchema = z.object({
  id: z.string().min(1).max(50),
  question: z.string().min(1).max(500),
  options: z.array(z.string().min(1).max(100)).min(2).max(10),
  descriptions: z.array(z.string().max(200)).optional(),
  multi: z.boolean().default(false),
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

  switch (p.type) {
    case "confirm":
      raw = await tracked(provider.confirm({
        body: p.body, title: p.title ?? "Confirmation",
        confirmLabel: p.yes, cancelLabel: p.no,
        position, projectPath,
      }), extra);
      break;

    case "pick":
      if (!p.choices?.length) throw new Error("choices required for type=pick");
      raw = await tracked(provider.choose({
        body: p.body, choices: p.choices, descriptions: p.descriptions,
        allowMultiple: p.multi, defaultSelection: p.default,
        position, projectPath,
      }), extra);
      break;

    case "text":
      raw = await tracked(provider.textInput({
        body: p.body, title: p.title ?? "Input",
        defaultValue: p.default ?? "", hidden: p.hidden,
        position, projectPath,
      }), extra);
      break;

    case "form": {
      if (!p.questions?.length) throw new Error("questions required for type=form");
      raw = await tracked(provider.questions({
        questions: p.questions.map(q => ({
          id: q.id, question: q.question,
          options: q.options.map((label, i) => ({ label, description: q.descriptions?.[i] })),
          multiSelect: q.multi,
        })),
        mode: p.mode as QuestionsMode,
        position, projectPath,
      }), extra);
      break;
    }
  }

  return { content: [{ type: "text", text: JSON.stringify(compactResponse(p.type, raw)) }] };
});

server.registerTool("notify", {
  description: "Non-blocking notification. Returns {success}.",
  inputSchema: z.object({
    body: z.string().min(1).max(1000),
    title: z.string().max(80).default("Notice"),
    sound: z.boolean().default(true),
  }),
}, async (p) => {
  provider.pulse();
  const r = await provider.notify({ body: p.body, title: p.title, sound: p.sound });
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
