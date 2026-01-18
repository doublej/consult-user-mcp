// Dialog position on screen
export type DialogPosition = "left" | "right" | "center";

// Confirmation dialog result
export interface ConfirmResult {
  dialogType: string;
  confirmed: boolean;
  cancelled: boolean;
  dismissed: boolean;
  answer: string | null;  // The selected button label
  comment: string | null;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  instruction?: string;
}

// Choice dialog result
export interface ChoiceResult {
  dialogType: string;
  answer: string | string[] | null;  // The selected choice(s)
  cancelled: boolean;
  dismissed: boolean;
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
  dialogType: string;
  answer: string | null;  // The entered text
  cancelled: boolean;
  dismissed: boolean;
  comment: string | null;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  instruction?: string;
}

// Notification result
export interface NotifyResult {
  dialogType: string;
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
  dialogType: string;
  answers: Record<string, string | string[]>;
  cancelled: boolean;
  dismissed: boolean;
  completedCount: number;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  instruction?: string;
}
