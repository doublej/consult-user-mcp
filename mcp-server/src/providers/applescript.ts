import { exec } from "child_process";
import { promisify } from "util";
import type { DialogProvider } from "./interface.js";
import type {
  DialogPosition,
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

const execAsync = promisify(exec);

/**
 * AppleScript-based dialog provider for macOS.
 */
export class AppleScriptDialogProvider implements DialogProvider {
  private clientName = "MCP";

  setClientName(name: string): void {
    this.clientName = name;
  }

  private buildTitle(baseTitle: string): string {
    return `${this.clientName} - ${baseTitle}`;
  }

  private escapeAppleScript(str: string): string {
    return str
      .replace(/\\/g, "\\\\")
      .replace(/"/g, '\\"')
      .replace(/\n/g, "\" & return & \"");
  }

  private spawnWindowMover(position: DialogPosition): void {
    if (position === "center") return;

    const xPos = position === "left" ? 50 : 1200;
    const yPos = 100;

    const moverScript = `
      delay 0.15
      tell application "System Events"
        repeat with p in (every process whose name is "osascript")
          try
            set position of window 1 of p to {${xPos}, ${yPos}}
          end try
        end repeat
      end tell
    `;

    execAsync(`osascript -e '${moverScript.replace(/'/g, "'\\''")}'`).catch(() => {});
  }

  private async runOsascript(script: string, position: DialogPosition = "center"): Promise<string> {
    this.spawnWindowMover(position);

    try {
      const { stdout } = await execAsync(`osascript -e '${script.replace(/'/g, "'\\''")}'`);
      return stdout.trim();
    } catch (error: unknown) {
      if (error instanceof Error && "stderr" in error) {
        const stderr = (error as { stderr: string }).stderr;
        if (stderr.includes("User canceled") || stderr.includes("-128")) {
          return "__CANCELLED__";
        }
      }
      throw error;
    }
  }

  private async getComment(position: DialogPosition): Promise<string | null> {
    const title = this.buildTitle("Add Comment");
    const script = `display dialog "Enter your comment:" with title "${this.escapeAppleScript(title)}" default answer "" buttons {"Cancel", "OK"} default button "OK"`;

    const result = await this.runOsascript(script, position);

    if (result === "__CANCELLED__" || result.includes("button returned:Cancel")) {
      return null;
    }

    const textMatch = result.match(/text returned:(.*)/);
    const comment = textMatch ? textMatch[1].trim() : "";
    return comment || null;
  }

  async confirm(opts: ConfirmOptions): Promise<ConfirmResult> {
    const title = this.buildTitle(opts.title);
    const COMMENT_OPTION = "+ Add a comment";
    const choices = [opts.confirmLabel, opts.cancelLabel, COMMENT_OPTION];
    const choiceList = choices.map(c => `"${this.escapeAppleScript(c)}"`).join(", ");

    const script = `choose from list {${choiceList}} with prompt "${this.escapeAppleScript(opts.message)}" with title "${this.escapeAppleScript(title)}" with multiple selections allowed default items {"${this.escapeAppleScript(opts.confirmLabel)}"}`;

    const result = await this.runOsascript(script, opts.position);

    if (result === "__CANCELLED__" || result === "false") {
      return { confirmed: false, cancelled: true, response: null, comment: null };
    }

    // Use indexOf instead of split to handle labels containing commas
    const hasComment = result.includes(COMMENT_OPTION);
    const confirmed = result.includes(opts.confirmLabel);
    const declined = result.includes(opts.cancelLabel);

    // Get comment if selected
    let comment: string | null = null;
    if (hasComment) {
      comment = await this.getComment(opts.position);
    }

    // Determine response - confirmed takes precedence if both selected
    if (confirmed) {
      return { confirmed: true, cancelled: false, response: opts.confirmLabel, comment };
    }
    if (declined) {
      return { confirmed: false, cancelled: false, response: opts.cancelLabel, comment };
    }

    // Only comment was selected, no actual choice
    return { confirmed: false, cancelled: true, response: null, comment };
  }

  async choose(opts: ChooseOptions): Promise<ChoiceResult> {
    const hasDescriptions = opts.descriptions && opts.descriptions.length === opts.choices.length;
    const displayChoices = hasDescriptions
      ? opts.choices.map((c, i) => `${c}  →  ${opts.descriptions![i]}`)
      : opts.choices;

    const COMMENT_OPTION = "+ Add a comment";
    const allChoices = [...displayChoices, COMMENT_OPTION];

    const title = this.buildTitle("Choose");
    const fullPrompt = `${opts.prompt}${hasDescriptions ? "\n\n(Option → Description)" : ""}`;

    const choiceList = allChoices.map(c => `"${this.escapeAppleScript(c)}"`).join(", ");
    let script = `choose from list {${choiceList}} with prompt "${this.escapeAppleScript(fullPrompt)}" with title "${this.escapeAppleScript(title)}" with multiple selections allowed`;

    if (opts.defaultSelection && opts.choices.includes(opts.defaultSelection)) {
      const idx = opts.choices.indexOf(opts.defaultSelection);
      const defaultDisplay = displayChoices[idx];
      script += ` default items {"${this.escapeAppleScript(defaultDisplay)}"}`;
    }

    const result = await this.runOsascript(script, opts.position);

    if (result === "__CANCELLED__" || result === "false") {
      return { selected: null, cancelled: true, description: null, comment: null };
    }

    // Match against known choices to handle labels containing commas
    const hasComment = result.includes(COMMENT_OPTION);
    const actualSelections = displayChoices.filter(choice => result.includes(choice));

    // Get comment if selected
    let comment: string | null = null;
    if (hasComment) {
      comment = await this.getComment(opts.position);
    }

    const parseSelection = (sel: string): { choice: string; description: string | null } => {
      if (hasDescriptions) {
        const idx = displayChoices.indexOf(sel);
        if (idx >= 0) {
          return { choice: opts.choices[idx], description: opts.descriptions![idx] };
        }
      }
      return { choice: sel, description: null };
    };

    if (actualSelections.length === 0) {
      return { selected: null, cancelled: true, description: null, comment };
    }

    if (opts.allowMultiple || actualSelections.length > 1) {
      const parsed = actualSelections.map(parseSelection);
      return {
        selected: parsed.map(s => s.choice),
        cancelled: false,
        description: null,
        descriptions: parsed.map(s => s.description),
        comment,
      };
    }

    const { choice, description } = parseSelection(actualSelections[0]);
    return { selected: choice, cancelled: false, description, comment };
  }

  async textInput(opts: TextInputOptions): Promise<TextInputResult> {
    const title = this.buildTitle(opts.title);
    // Three buttons: Cancel, + Comment, OK
    let script = `display dialog "${this.escapeAppleScript(opts.prompt)}" with title "${this.escapeAppleScript(title)}" default answer "${this.escapeAppleScript(opts.defaultValue)}" buttons {"Cancel", "+ Comment", "OK"} default button "OK"`;

    if (opts.hidden) {
      script += " with hidden answer";
    }

    const result = await this.runOsascript(script, opts.position);

    if (result === "__CANCELLED__") {
      return { text: null, cancelled: true, comment: null };
    }

    // Check if user clicked Cancel button
    if (result.includes("button returned:Cancel")) {
      return { text: null, cancelled: true, comment: null };
    }

    const textMatch = result.match(/text returned:(.*)/);
    const text = textMatch ? textMatch[1] : "";

    // If user clicked "+ Comment", get comment
    if (result.includes("button returned:+ Comment")) {
      const comment = await this.getComment(opts.position);
      return { text, cancelled: false, comment };
    }

    return { text, cancelled: false, comment: null };
  }

  async notify(opts: NotifyOptions): Promise<NotifyResult> {
    const title = this.buildTitle(opts.title);
    let script = `display notification "${this.escapeAppleScript(opts.message)}" with title "${this.escapeAppleScript(title)}"`;

    if (opts.subtitle) {
      script += ` subtitle "${this.escapeAppleScript(opts.subtitle)}"`;
    }

    if (opts.sound) {
      script += ` sound name "default"`;
    }

    await this.runOsascript(script);
    return { success: true };
  }

  async speak(opts: SpeakOptions): Promise<SpeakResult> {
    const escapedText = opts.text.replace(/"/g, '\\"').replace(/`/g, "\\`");
    let command = `say -r ${opts.rate}`;

    if (opts.voice) {
      command += ` -v "${opts.voice}"`;
    }

    command += ` "${escapedText}"`;
    await execAsync(command);

    return { success: true };
  }
}
