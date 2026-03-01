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
  PreviewOptions,
  PreviewResult,
  QuestionsOptions,
  QuestionsResult,
  TweakOptions,
  TweakResult,
  ProposeLayoutOptions,
  ProposeLayoutResult,
} from "../types.js";

const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// App bundle: Resources/mcp-server/dist/providers -> Resources/<subdir>/<subdir>
// Dev: mcp-server/dist/providers -> <subdir>/.build/{debug,release}/<binaryName>
function findCli(subdir: string, binaryName: string): string | null {
  const base = join(__dirname, "..", "..", "..", subdir);
  const candidates = [
    join(base, subdir),
    join(base, ".build", "debug", binaryName),
    join(base, ".build", "release", binaryName),
  ];
  return candidates.find(c => existsSync(c)) ?? null;
}

function getCliPath(): string {
  const path = findCli("dialog-cli", "DialogCLI");
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

function getSketchCliPath(): string {
  const path = findCli("sketch-cli", "SketchCLI");
  if (!path) {
    const appBundlePath = join(__dirname, "..", "..", "..", "sketch-cli", "sketch-cli");
    const devPath = join(__dirname, "..", "..", "..", "sketch-cli", ".build", "release", "SketchCLI");
    throw new Error(
      `Sketch CLI not found.\n\n` +
      `Searched:\n  - ${appBundlePath}\n  - ${devPath}\n\n` +
      `Build it: cd sketch-cli && swift build -c release`
    );
  }
  return path;
}

let sketchCliPath: string | null = null;

/**
 * Swift-based native dialog provider for macOS.
 * Uses a compiled Swift CLI for native AppKit dialogs.
 */
export class SwiftDialogProvider implements DialogProvider {
  private clientName = "MCP";
  private activeDialog: Promise<unknown> | null = null;

  setClientName(name: string): void {
    this.clientName = name;
  }

  private async runCli<T>(command: string, args: object, projectPath?: string): Promise<T> {
    if (command !== "notify" && command !== "preview" && command !== "pulse" && this.activeDialog) {
      return this.activeDialog as Promise<T>;
    }
    const promise = this.execCli<T>(command, args, projectPath);
    if (command !== "notify" && command !== "preview" && command !== "pulse") {
      this.activeDialog = promise;
      promise.finally(() => { this.activeDialog = null; }).catch(() => {});
    }
    return promise;
  }

  private async execCli<T>(command: string, args: object, projectPath?: string): Promise<T> {
    if (!cliPath) cliPath = getCliPath();
    const jsonArg = JSON.stringify(args);
    let stdout: string;
    try {
      const result = await execFileAsync(cliPath, [command, jsonArg], {
        env: {
          ...process.env,
          MCP_CLIENT_NAME: this.clientName,
          ...(projectPath ? { MCP_PROJECT_PATH: projectPath } : {}),
        },
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
    const { projectPath, ...args } = opts;
    return this.runCli<ConfirmResult>("confirm", args, projectPath);
  }

  async choose(opts: ChooseOptions): Promise<ChoiceResult> {
    const { projectPath, ...args } = opts;
    return this.runCli<ChoiceResult>("choose", args, projectPath);
  }

  async textInput(opts: TextInputOptions): Promise<TextInputResult> {
    const { projectPath, ...args } = opts;
    return this.runCli<TextInputResult>("textInput", args, projectPath);
  }

  async notify(opts: NotifyOptions): Promise<NotifyResult> {
    const { projectPath, ...args } = opts;
    return this.runCli<NotifyResult>("notify", args, projectPath);
  }

  async preview(opts: PreviewOptions): Promise<PreviewResult> {
    return this.runCli<PreviewResult>("preview", opts);
  }

  async questions(opts: QuestionsOptions): Promise<QuestionsResult> {
    const { projectPath, ...args } = opts;
    return this.runCli<QuestionsResult>("questions", args, projectPath);
  }

  async tweak(opts: TweakOptions): Promise<TweakResult> {
    const { projectPath, ...args } = opts;
    return this.runCli<TweakResult>("tweak", args, projectPath);
  }

  async pulse(): Promise<void> {
    // Fire and forget - don't wait for completion
    if (!cliPath) cliPath = getCliPath();
    execFileAsync(cliPath, ["pulse"]).catch(() => {});
  }

  private async execSketchCli<T>(command: string, args?: object, signal?: AbortSignal): Promise<T> {
    if (!sketchCliPath) sketchCliPath = getSketchCliPath();
    const cliArgs = args ? [command, JSON.stringify(args)] : [command];
    let stdout: string;
    let stderr = "";
    try {
      const result = await execFileAsync(sketchCliPath, cliArgs, signal ? { signal } : {});
      stdout = result.stdout;
      stderr = result.stderr;
    } catch (err: unknown) {
      const e = err as { code?: string | number; signal?: string; stderr?: string; message?: string; name?: string };
      if (e.name === "AbortError" || e.code === "ABORT_ERR") {
        throw new Error(`Sketch CLI '${command}' was cancelled`);
      }
      if (e.code === "ENOENT") {
        throw new Error(`Sketch CLI not found at: ${sketchCliPath}`);
      }
      if (typeof e.code === "number") {
        const errOut = e.stderr?.trim();
        throw new Error(`Sketch CLI '${command}' exited with code ${e.code}${errOut ? `: ${errOut}` : ""}`);
      }
      if (e.signal) {
        throw new Error(`Sketch CLI '${command}' killed by signal ${e.signal}`);
      }
      throw new Error(`Sketch CLI '${command}' failed: ${e.message ?? String(err)}`);
    }
    try {
      return JSON.parse(stdout.trim()) as T;
    } catch {
      const hint = stderr.trim() ? `\nStderr: ${stderr.trim().slice(0, 200)}` : "";
      throw new Error(`Sketch CLI '${command}' returned invalid JSON: ${stdout.slice(0, 200)}${hint}`);
    }
  }

  async proposeLayout(opts: ProposeLayoutOptions, signal?: AbortSignal): Promise<ProposeLayoutResult> {
    return this.execSketchCli<ProposeLayoutResult>("propose", opts, signal);
  }

}
