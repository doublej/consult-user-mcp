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
  // Installed alongside mcp-server
  const siblingPath = join(__dirname, "..", "..", "..", "dialog-cli-windows", "dialog-cli-windows.exe");
  if (existsSync(siblingPath)) return siblingPath;

  // Dev: published output
  const devPath = join(__dirname, "..", "..", "..", "dialog-cli-windows", "bin", "Release", "net8.0-windows", "win-x64", "publish", "dialog-cli-windows.exe");
  if (existsSync(devPath)) return devPath;

  // Dev: debug build
  const debugPath = join(__dirname, "..", "..", "..", "dialog-cli-windows", "bin", "Debug", "net8.0-windows", "win-x64", "dialog-cli-windows.exe");
  if (existsSync(debugPath)) return debugPath;

  return null;
}

function getCliPath(): string {
  const path = findDialogCli();
  if (!path) {
    throw new Error(
      `Windows Dialog CLI not found.\n\n` +
      `Setup instructions:\n` +
      `  1. Install .NET 8 SDK\n` +
      `  2. cd dialog-cli-windows && dotnet publish -r win-x64 --self-contained`
    );
  }
  return path;
}

let cliPath: string | null = null;

/**
 * Windows-based native dialog provider using WPF.
 * Uses a compiled C# CLI for native Windows dialogs.
 */
export class WindowsDialogProvider implements DialogProvider {
  private clientName = "MCP";

  setClientName(name: string): void {
    this.clientName = name;
  }

  private async runCli<T>(command: string, args: object, projectPath?: string): Promise<T> {
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
        throw new Error(`Windows Dialog CLI not found at: ${cliPath}`);
      }
      if (typeof e.code === "number") {
        const stderr = e.stderr?.trim();
        throw new Error(`Windows Dialog CLI '${command}' exited with code ${e.code}${stderr ? `: ${stderr}` : ""}`);
      }
      if (e.signal) {
        throw new Error(`Windows Dialog CLI '${command}' killed by signal ${e.signal}`);
      }
      throw new Error(`Windows Dialog CLI '${command}' failed: ${e.message ?? String(err)}`);
    }
    try {
      return JSON.parse(stdout.trim()) as T;
    } catch {
      throw new Error(`Windows Dialog CLI '${command}' returned invalid JSON: ${stdout.slice(0, 200)}`);
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
    return this.runCli<NotifyResult>("notify", opts);
  }

  async questions(opts: QuestionsOptions): Promise<QuestionsResult> {
    const { projectPath, ...args } = opts;
    return this.runCli<QuestionsResult>("questions", args, projectPath);
  }

  async pulse(): Promise<void> {
    // No-op on Windows (no tray app to keep alive)
  }
}
