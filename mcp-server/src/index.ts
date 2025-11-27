import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { SwiftDialogProvider } from "./providers/swift.js";
import type { DialogPosition } from "./types.js";

// Server initialization
const server = new McpServer({
  name: "speak-mcp-server",
  version: "1.0.0",
});

// Dialog provider - Swift for native macOS dialogs
const provider = new SwiftDialogProvider();

// =============================================================================
// Tool: ask_confirmation
// =============================================================================
const AskConfirmationSchema = z.object({
  message: z.string().min(1).max(500).describe("The question or message to display to the user"),
  title: z.string().max(100).default("Confirmation").describe("Optional title for the dialog window"),
  confirm_label: z.string().max(20).default("Yes").describe("Label for the confirm button"),
  cancel_label: z.string().max(20).default("No").describe("Label for the cancel/decline button"),
  position: z.enum(["left", "right", "center"]).default("left").describe("Dialog position on screen (default: left)"),
}).strict();

server.registerTool(
  "ask_confirmation",
  {
    title: "Ask User Confirmation",
    description: `CHECKPOINT: Show Yes/No dialog. Use this as a checkpoint before major decisions or actions - it replaces AskUserQuestion for MCP workflows. Returns {confirmed, cancelled, response}. User has 10 min to respond.`,
    inputSchema: AskConfirmationSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: false,
      openWorldHint: true,
    },
  },
  async (params) => {
    const result = await provider.confirm({
      message: params.message,
      title: params.title ?? "Confirmation",
      confirmLabel: params.confirm_label ?? "Yes",
      cancelLabel: params.cancel_label ?? "No",
      position: (params.position ?? "left") as DialogPosition,
    });

    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
    };
  }
);

// =============================================================================
// Tool: ask_multiple_choice
// =============================================================================
const AskMultipleChoiceSchema = z.object({
  prompt: z.string().min(1).max(500).describe("The question or instruction to display"),
  choices: z.array(z.string().min(1).max(100)).min(2).max(20).describe("List of options for the user to choose from"),
  descriptions: z.array(z.string().max(200)).optional().describe("Optional descriptions for each choice (displayed below list). Array must match choices length."),
  allow_multiple: z.boolean().default(false).describe("If true, user can select multiple items"),
  default_selection: z.string().optional().describe("Which item to pre-select (must match a choice exactly)"),
  position: z.enum(["left", "right", "center"]).default("left").describe("Dialog position on screen (default: left)"),
}).strict();

server.registerTool(
  "ask_multiple_choice",
  {
    title: "Ask Multiple Choice",
    description: `CHECKPOINT: Show list picker dialog. Use this as a checkpoint when offering user choices or gathering preferences - it replaces AskUserQuestion for MCP workflows. Returns {selected, cancelled, description}. User has 10 min to respond.`,
    inputSchema: AskMultipleChoiceSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: false,
      openWorldHint: true,
    },
  },
  async (params) => {
    const result = await provider.choose({
      prompt: params.prompt,
      choices: params.choices,
      descriptions: params.descriptions,
      allowMultiple: params.allow_multiple ?? false,
      defaultSelection: params.default_selection,
      position: (params.position ?? "left") as DialogPosition,
    });

    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
    };
  }
);

// =============================================================================
// Tool: ask_text_input
// =============================================================================
const AskTextInputSchema = z.object({
  prompt: z.string().min(1).max(500).describe("The question or instruction to display"),
  title: z.string().max(100).default("Input").describe("Optional title for the dialog window"),
  default_value: z.string().max(1000).default("").describe("Pre-filled text in the input field"),
  hidden: z.boolean().default(false).describe("If true, input is masked (for passwords/sensitive data)"),
  position: z.enum(["left", "right", "center"]).default("left").describe("Dialog position on screen (default: left)"),
}).strict();

server.registerTool(
  "ask_text_input",
  {
    title: "Ask Text Input",
    description: `CHECKPOINT: Show text input dialog. Use this as a checkpoint when needing free-form user input - it replaces AskUserQuestion for MCP workflows. Returns {text, cancelled}. Supports hidden input for passwords. User has 10 min to respond.`,
    inputSchema: AskTextInputSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: false,
      openWorldHint: true,
    },
  },
  async (params) => {
    const result = await provider.textInput({
      prompt: params.prompt,
      title: params.title ?? "Input",
      defaultValue: params.default_value ?? "",
      hidden: params.hidden ?? false,
      position: (params.position ?? "left") as DialogPosition,
    });

    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
    };
  }
);

// =============================================================================
// Tool: notify_user
// =============================================================================
const NotifyUserSchema = z.object({
  message: z.string().min(1).max(500).describe("The notification message to display"),
  title: z.string().max(100).default("Notice").describe("Title for the notification"),
  subtitle: z.string().max(200).optional().describe("Optional subtitle text"),
  sound: z.boolean().default(true).describe("Play notification sound"),
}).strict();

server.registerTool(
  "notify_user",
  {
    title: "Notify User",
    description: `Show macOS notification banner. Non-blocking, no user response needed. Returns {success}.`,
    inputSchema: NotifyUserSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: false,
    },
  },
  async (params) => {
    const result = await provider.notify({
      message: params.message,
      title: params.title ?? "Notice",
      subtitle: params.subtitle,
      sound: params.sound ?? true,
    });

    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
    };
  }
);

// =============================================================================
// Tool: speak_text
// =============================================================================
const SpeakTextSchema = z.object({
  text: z.string().min(1).max(5000).describe("The text to speak aloud"),
  voice: z.string().optional().describe("Voice name (e.g., 'Samantha', 'Daniel', 'Karen'). Run 'say -v ?' in terminal to see available voices."),
  rate: z.number().min(50).max(500).default(200).describe("Speech rate in words per minute (default: 200)"),
}).strict();

server.registerTool(
  "speak_text",
  {
    title: "Speak Text Aloud",
    description: `Text-to-speech via macOS 'say' command. Returns {success}.`,
    inputSchema: SpeakTextSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: false,
    },
  },
  async (params) => {
    const result = await provider.speak({
      text: params.text,
      voice: params.voice,
      rate: params.rate ?? 200,
    });

    return {
      content: [{ type: "text", text: JSON.stringify(result) }],
    };
  }
);

// =============================================================================
// Run the server
// =============================================================================
async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);

  // Set client name from MCP initialization
  const clientInfo = server.server.getClientVersion();
  provider.setClientName(clientInfo?.name ?? "MCP");

  console.error("Speak MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
