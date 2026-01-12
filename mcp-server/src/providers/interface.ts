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

/**
 * Interface for dialog providers.
 * Implementations handle platform-specific dialog rendering.
 */
export interface DialogProvider {
  /**
   * Set the client name for dialog titles.
   * Called once after MCP initialization.
   */
  setClientName(name: string): void;

  /**
   * Display a confirmation dialog with Yes/No buttons.
   */
  confirm(opts: ConfirmOptions): Promise<ConfirmResult>;

  /**
   * Display a list of choices for the user to select from.
   */
  choose(opts: ChooseOptions): Promise<ChoiceResult>;

  /**
   * Display a text input dialog.
   */
  textInput(opts: TextInputOptions): Promise<TextInputResult>;

  /**
   * Display a notification (non-blocking).
   */
  notify(opts: NotifyOptions): Promise<NotifyResult>;

  /**
   * Display multiple questions in a single dialog.
   * Supports wizard and accordion modes.
   */
  questions(opts: QuestionsOptions): Promise<QuestionsResult>;
}
