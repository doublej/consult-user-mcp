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
  askDifferently?: string;
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
  askDifferently?: string;
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
  askDifferently?: string;
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
  projectPath: string;
}

// Options for choice dialog
export interface ChooseOptions {
  body: string;
  title?: string;
  choices: string[];
  descriptions?: string[];
  allowMultiple: boolean;
  defaultSelection?: string;
  position: DialogPosition;
  projectPath: string;
}

// Options for text input dialog
export interface TextInputOptions {
  body: string;
  title: string;
  defaultValue: string;
  hidden: boolean;
  position: DialogPosition;
  projectPath: string;
}

// Options for notification
export interface NotifyOptions {
  body: string;
  title: string;
  sound: boolean;
  projectPath?: string;
}

// Options for preview (review-before-send)
export interface PreviewOptions {
  body: string;
}

// Result for preview
export interface PreviewResult {
  dialogType: string;
  success: boolean;
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
  body?: string;
  title?: string;
  questions: Question[];
  mode: QuestionsMode;
  position: DialogPosition;
  projectPath: string;
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
  askDifferently?: string;
  instruction?: string;
}

// Tweak parameter definition
export interface TweakParameter {
  id: string;
  label: string;
  element?: string;
  file: string;
  // CSS reference (resolved by server)
  selector?: string;
  property?: string;
  index?: number;
  fn?: string;
  // Text search (resolved by server)
  search?: string;
  // Direct location — filled by resolver if using CSS reference or text search
  line?: number;
  column?: number;
  expectedText?: string;
  current?: number;
  // Range (always required)
  min: number;
  max: number;
  step?: number;
  unit?: string;
}

// Options for tweak dialog
export interface TweakOptions {
  body: string;
  parameters: TweakParameter[];
  title?: string;
  position?: DialogPosition;
  projectPath?: string;
}

// Result for tweak dialog
export interface TweakResult {
  dialogType: string;
  answers: Record<string, number>;
  action?: "file" | "agent";
  cancelled: boolean;
  dismissed: boolean;
  snoozed?: boolean;
  snoozeMinutes?: number;
  remainingSeconds?: number;
  feedbackText?: string;
  askDifferently?: string;
  instruction?: string;
}
