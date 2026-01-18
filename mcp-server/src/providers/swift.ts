import { execFile } from "child_process";
import { promisify } from "util";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { existsSync } from "fs";
import type { DialogProvider } from "./interface.js";
import type {
  ConfirmOptions,
  ConfirmResult,
  ChooseOptions,
  ChoiceResult,
  TextInputOptions,
  TextInputResult,
  NotifyOptions,
  NotifyResult,
  QuestionsOptions,
  QuestionsResult,
} from "../types.js";

const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function findDialogCli(): string | null {
  // App bundle: Resources/mcp-server/dist/providers -> Resources/dialog-cli/dialog-cli
  const appBundlePath = join(__dirname, "..", "..", "..", "dialog-cli", "dialog-cli");
  if (existsSync(appBundlePath)) return appBundlePath;

  // Dev: speak/mcp-server/dist/providers -> speak/dialog-cli/.build/release/DialogCLI
  const devPath = join(__dirname, "..", "..", "..", "dialog-cli", ".build", "release", "DialogCLI");
  if (existsSync(devPath)) return devPath;

  return null;
}

function getCliPath(): string {
  const path = findDialogCli();
  if (!path) {
    const appBundlePath = join(__dirname, "..", "..", "..", "dialog-cli", "dialog-cli");
    const devPath = join(__dirname, "..", "..", "..", "dialog-cli", ".build", "release", "DialogCLI");
    throw new Error(
      `Dialog CLI not found.\n\n` +
      `Searched:\n  - ${appBundlePath}\n  - ${devPath}\n\n` +
      `Setup instructions:\n` +
      `  1. Install via: curl -fsSL https://github.com/doublej/consult-user-mcp/releases/latest/download/install.sh | bash\n` +
      `  2. Or build from source: cd dialog-cli && swift build -c release`
    );
  }
  return path;
}

let cliPath: string | null = null;

/**
 * Swift-based native dialog provider for macOS.
 * Uses a compiled Swift CLI for native AppKit dialogs.
 */
export class SwiftDialogProvider implements DialogProvider {
  private clientName = "MCP";

  setClientName(name: string): void {
    this.clientName = name;
  }

  private async runCli<T>(command: string, args: object): Promise<T> {
    if (!cliPath) cliPath = getCliPath();
    const jsonArg = JSON.stringify(args);
    let stdout: string;
    try {
      const result = await execFileAsync(cliPath, [command, jsonArg], {
        env: { ...process.env, MCP_CLIENT_NAME: this.clientName },
      });
      stdout = result.stdout;
    } catch (err: unknown) {
      const e = err as { code?: string | number; signal?: string; stderr?: string; message?: string };
      if (e.code === "ENOENT") {
        throw new Error(`Dialog CLI not found at: ${cliPath}`);
      }
      if (typeof e.code === "number") {
        const stderr = e.stderr?.trim();
        throw new Error(`Dialog CLI '${command}' exited with code ${e.code}${stderr ? `: ${stderr}` : ""}`);
      }
      if (e.signal) {
        throw new Error(`Dialog CLI '${command}' killed by signal ${e.signal}`);
      }
      throw new Error(`Dialog CLI '${command}' failed: ${e.message ?? String(err)}`);
    }
    try {
      return JSON.parse(stdout.trim()) as T;
    } catch {
      throw new Error(`Dialog CLI '${command}' returned invalid JSON: ${stdout.slice(0, 200)}`);
    }
  }

  async confirm(opts: ConfirmOptions): Promise<ConfirmResult> {
    return this.runCli<ConfirmResult>("confirm", {
      body: opts.body,
      title: opts.title,
      confirmLabel: opts.confirmLabel,
      cancelLabel: opts.cancelLabel,
      position: opts.position,
    });
  }

  async choose(opts: ChooseOptions): Promise<ChoiceResult> {
    return this.runCli<ChoiceResult>("choose", {
      body: opts.body,
      choices: opts.choices,
      descriptions: opts.descriptions,
      allowMultiple: opts.allowMultiple,
      defaultSelection: opts.defaultSelection,
      position: opts.position,
    });
  }

  async textInput(opts: TextInputOptions): Promise<TextInputResult> {
    return this.runCli<TextInputResult>("textInput", {
      body: opts.body,
      title: opts.title,
      defaultValue: opts.defaultValue,
      hidden: opts.hidden,
      position: opts.position,
    });
  }

  async notify(opts: NotifyOptions): Promise<NotifyResult> {
    return this.runCli<NotifyResult>("notify", {
      body: opts.body,
      title: opts.title,
      sound: opts.sound,
    });
  }

  async questions(opts: QuestionsOptions): Promise<QuestionsResult> {
    return this.runCli<QuestionsResult>("questions", {
      questions: opts.questions,
      mode: opts.mode,
      position: opts.position,
    });
  }

  async pulse(): Promise<void> {
    // Fire and forget - don't wait for completion
    if (!cliPath) cliPath = getCliPath();
    execFileAsync(cliPath, ["pulse"]).catch(() => {});
  }
}
