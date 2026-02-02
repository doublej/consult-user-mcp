import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { SwiftDialogProvider } from "./providers/swift.js";
import type { DialogPosition, QuestionsMode } from "./types.js";
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

const server = new McpServer({ name: "consult-user-mcp-server", version: "1.0.0" });
const provider = new SwiftDialogProvider();
const pos = z.enum(["left", "right", "center"]).default("left");
const projectPath = z.string().describe("Project path for context badge");

server.registerTool("ask_confirmation", {
  description: "Yes/No dialog. Returns {confirmed, cancelled, answer}. 10 min timeout. User may snooze (snoozed, snoozeMinutes, remainingSeconds) or provide feedback (feedbackText) instead. IMPORTANT: If snoozed, all subsequent dialog calls return {snoozed: true, remainingSeconds} without showing dialog - run `sleep <remainingSeconds>` then retry.",
  inputSchema: z.object({
    body: z.string().min(1).max(1000),
    title: z.string().max(80).default("Confirmation"),
    confirm_label: z.string().max(20).default("Yes"),
    cancel_label: z.string().max(20).default("No"),
    position: pos,
    project_path: projectPath,
  }),
}, async (p, extra) => {
  provider.pulse();
  const r = await withHeartbeat(withTimeout(provider.confirm({
    body: p.body, title: p.title ?? "Confirmation",
    confirmLabel: p.confirm_label ?? "Yes", cancelLabel: p.cancel_label ?? "No",
    position: (p.position ?? "left") as DialogPosition,
    projectPath: p.project_path,
  }), DIALOG_TIMEOUT_MS), extra);
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

server.registerTool("ask_multiple_choice", {
  description: "List picker dialog. Returns {answer, cancelled, description}. 10 min timeout. User may snooze (snoozed, snoozeMinutes, remainingSeconds) or provide feedback (feedbackText) instead. IMPORTANT: If snoozed, all subsequent dialog calls return {snoozed: true, remainingSeconds} without showing dialog - run `sleep <remainingSeconds>` then retry.",
  inputSchema: z.object({
    body: z.string().min(1).max(1000),
    choices: z.array(z.string().min(1).max(100)).min(2).max(20),
    descriptions: z.array(z.string().max(200)).optional(),
    allow_multiple: z.boolean().default(true),
    default_selection: z.string().optional(),
    position: pos,
    project_path: projectPath,
  }),
}, async (p, extra) => {
  provider.pulse();
  const r = await withHeartbeat(withTimeout(provider.choose({
    body: p.body, choices: p.choices, descriptions: p.descriptions,
    allowMultiple: p.allow_multiple ?? true, defaultSelection: p.default_selection,
    position: (p.position ?? "left") as DialogPosition,
    projectPath: p.project_path,
  }), DIALOG_TIMEOUT_MS), extra);
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

server.registerTool("ask_text_input", {
  description: "Text input dialog. Returns {answer, cancelled}. Supports hidden input. 10 min timeout. User may snooze (snoozed, snoozeMinutes, remainingSeconds) or provide feedback (feedbackText) instead. IMPORTANT: If snoozed, all subsequent dialog calls return {snoozed: true, remainingSeconds} without showing dialog - run `sleep <remainingSeconds>` then retry.",
  inputSchema: z.object({
    body: z.string().min(1).max(1000),
    title: z.string().max(80).default("Input"),
    default_value: z.string().max(1000).default(""),
    hidden: z.boolean().default(false),
    position: pos,
    project_path: projectPath,
  }),
}, async (p, extra) => {
  provider.pulse();
  const r = await withHeartbeat(withTimeout(provider.textInput({
    body: p.body, title: p.title ?? "Input",
    defaultValue: p.default_value ?? "", hidden: p.hidden ?? false,
    position: (p.position ?? "left") as DialogPosition,
    projectPath: p.project_path,
  }), DIALOG_TIMEOUT_MS), extra);
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

server.registerTool("notify_user", {
  description: "Show macOS notification banner. Non-blocking, no user response needed. Returns {success}.",
  inputSchema: z.object({
    body: z.string().min(1).max(1000),
    title: z.string().max(80).default("Notice"),
    sound: z.boolean().default(true),
  }),
}, async (p) => {
  provider.pulse();
  const r = await provider.notify({
    body: p.body, title: p.title ?? "Notice",
    sound: p.sound ?? true,
  });
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

const questionSchema = z.object({
  id: z.string().min(1).max(50),
  question: z.string().min(1).max(500),
  options: z.array(z.object({
    label: z.string().min(1).max(100),
    description: z.string().max(200).optional(),
  })).min(2).max(10),
  multi_select: z.boolean().default(false),
});

server.registerTool("ask_questions", {
  description: "Multi-question dialog. Modes: wizard (prev/next), accordion (collapsible). Returns {answers, cancelled, completedCount}. User may snooze (snoozed, snoozeMinutes, remainingSeconds) or provide feedback (feedbackText) instead. IMPORTANT: If snoozed, all subsequent dialog calls return {snoozed: true, remainingSeconds} without showing dialog - run `sleep <remainingSeconds>` then retry.",
  inputSchema: z.object({
    questions: z.array(questionSchema).min(1).max(10),
    mode: z.enum(["wizard", "accordion"]).default("wizard"),
    position: pos,
    project_path: projectPath,
  }),
}, async (p, extra) => {
  provider.pulse();
  const r = await withHeartbeat(withTimeout(provider.questions({
    questions: p.questions.map(q => ({
      id: q.id,
      question: q.question,
      options: q.options,
      multiSelect: q.multi_select ?? false,
    })),
    mode: (p.mode ?? "wizard") as QuestionsMode,
    position: (p.position ?? "left") as DialogPosition,
    projectPath: p.project_path,
  }), DIALOG_TIMEOUT_MS), extra);
  return { content: [{ type: "text", text: JSON.stringify(r) }] };
});

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  provider.setClientName(server.server.getClientVersion()?.name ?? "MCP");
  console.error("Consult User MCP Server running on stdio");
}

main().catch((e) => { console.error("Server error:", e); process.exit(1); });
