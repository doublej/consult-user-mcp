import { execFile } from "child_process";
import { promisify } from "util";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
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
  SpeakOptions,
  SpeakResult,
} from "../types.js";

const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
// dialog-cli is in the shared location: ../../../dialog-cli/dialog-cli
const CLI_PATH = join(__dirname, "..", "..", "..", "dialog-cli", "dialog-cli");

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
      message: opts.message,
      title: opts.title,
      confirmLabel: opts.confirmLabel,
      cancelLabel: opts.cancelLabel,
      position: opts.position,
    });
  }

  async choose(opts: ChooseOptions): Promise<ChoiceResult> {
    return this.runCli<ChoiceResult>("choose", {
      prompt: opts.prompt,
      choices: opts.choices,
      descriptions: opts.descriptions,
      allowMultiple: opts.allowMultiple,
      defaultSelection: opts.defaultSelection,
      position: opts.position,
    });
  }

  async textInput(opts: TextInputOptions): Promise<TextInputResult> {
    return this.runCli<TextInputResult>("textInput", {
      prompt: opts.prompt,
      title: opts.title,
      defaultValue: opts.defaultValue,
      hidden: opts.hidden,
      position: opts.position,
    });
  }

  async notify(opts: NotifyOptions): Promise<NotifyResult> {
    return this.runCli<NotifyResult>("notify", {
      message: opts.message,
      title: opts.title,
      subtitle: opts.subtitle,
      sound: opts.sound,
    });
  }

  async speak(opts: SpeakOptions): Promise<SpeakResult> {
    return this.runCli<SpeakResult>("speak", {
      text: opts.text,
      voice: opts.voice,
      rate: opts.rate,
    });
  }
}
