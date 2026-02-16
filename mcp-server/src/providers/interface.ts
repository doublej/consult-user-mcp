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
   * Send a pulse to keep the macOS app active.
   * Called before each dialog to ensure the app is responsive.
   */
  pulse(): Promise<void>;

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
   * Display a preview of the response before sending (non-blocking, no history).
   */
  preview(opts: PreviewOptions): Promise<PreviewResult>;

  /**
   * Display multiple questions in a single dialog.
   * Supports wizard and accordion modes.
   */
  questions(opts: QuestionsOptions): Promise<QuestionsResult>;
}
