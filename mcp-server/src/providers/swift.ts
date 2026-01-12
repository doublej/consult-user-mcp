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

function findDialogCli(): string {
  // App bundle: Resources/mcp-server/dist/providers -> Resources/dialog-cli/dialog-cli
  const appBundlePath = join(__dirname, "..", "..", "..", "dialog-cli", "dialog-cli");
  if (existsSync(appBundlePath)) return appBundlePath;

  // Dev: speak/mcp-server/dist/providers -> speak/dialog-cli/.build/release/DialogCLI
  const devPath = join(__dirname, "..", "..", "..", "dialog-cli", ".build", "release", "DialogCLI");
  if (existsSync(devPath)) return devPath;

  return devPath;
}

const CLI_PATH = findDialogCli();

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
    const jsonArg = JSON.stringify(args);
    const { stdout } = await execFileAsync(CLI_PATH, [command, jsonArg], {
      env: { ...process.env, MCP_CLIENT_NAME: this.clientName },
    });
    return JSON.parse(stdout.trim()) as T;
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
    execFileAsync(CLI_PATH, ["pulse"]).catch(() => {});
  }
}
