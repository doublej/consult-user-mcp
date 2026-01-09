// Dialog position on screen
export type DialogPosition = "left" | "right" | "center";

// Base result for all dialogs
export interface DialogResult<T> {
  value: T | null;
  cancelled: boolean;
  comment: string | null;
}

// Confirmation dialog result
export interface ConfirmResult {
  confirmed: boolean;
  cancelled: boolean;
  response: string | null;
  comment: string | null;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  instruction?: string;
}

// Choice dialog result
export interface ChoiceResult {
  selected: string | string[] | null;
  cancelled: boolean;
  description: string | null;
  descriptions?: (string | null)[];
  comment: string | null;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  instruction?: string;
}

// Text input dialog result
export interface TextInputResult {
  text: string | null;
  cancelled: boolean;
  comment: string | null;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  instruction?: string;
}

// Notification result
export interface NotifyResult {
  success: boolean;
}

// TTS result
export interface TtsResult {
  success: boolean;
}

// Options for confirmation dialog
export interface ConfirmOptions {
  body: string;
  title: string;
  confirmLabel: string;
  cancelLabel: string;
  position: DialogPosition;
}

// Options for choice dialog
export interface ChooseOptions {
  body: string;
  choices: string[];
  descriptions?: string[];
  allowMultiple: boolean;
  defaultSelection?: string;
  position: DialogPosition;
}

// Options for text input dialog
export interface TextInputOptions {
  body: string;
  title: string;
  defaultValue: string;
  hidden: boolean;
  position: DialogPosition;
}

// Options for notification
export interface NotifyOptions {
  body: string;
  title: string;
  sound: boolean;
}

// Options for TTS
export interface TtsOptions {
  text: string;
  voice?: string;
  rate: number;
}

// Question definition for multi-question dialogs
export interface Question {
  id: string;
  question: string;
  options: { label: string; description?: string }[];
  multiSelect: boolean;
}

// Mode for multi-question display
export type QuestionsMode = "wizard" | "accordion";

// Options for multi-question dialog
export interface QuestionsOptions {
  questions: Question[];
  mode: QuestionsMode;
  position: DialogPosition;
}

// Result for multi-question dialog
export interface QuestionsResult {
  answers: Record<string, string | string[]>;
  cancelled: boolean;
  completedCount: number;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  instruction?: string;
}
