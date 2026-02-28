import type { ConfirmResult, ChoiceResult, TextInputResult, QuestionsResult, TweakResult } from "./types.js";

type AskType = "confirm" | "pick" | "text" | "form" | "tweak";
type RawResult = ConfirmResult | ChoiceResult | TextInputResult | QuestionsResult | TweakResult;

function stripNulls(obj: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v != null) out[k] = v;
  }
  return out;
}

export function compactResponse(type: AskType, raw: unknown): Record<string, unknown> {
  const r = raw as RawResult;
  const out: Record<string, unknown> = {};

  // Snooze takes priority
  if (r.snoozed) {
    out.snoozed = true;
    if (r.remainingSeconds != null) out.remainingSeconds = r.remainingSeconds;
    return out;
  }

  // Ask differently takes priority over feedback/normal/cancelled
  if (r.askDifferently) return { askDifferently: r.askDifferently };

  // Feedback — accumulate (don't early-return) so partial answers are included
  if (r.feedbackText) out.feedbackText = r.feedbackText;

  // Cancelled/dismissed (skip when feedback — user gave input, not a cancel)
  if (!r.feedbackText && (r.cancelled || r.dismissed)) out.cancelled = true;

  // Type-specific answer extraction
  if (type === "confirm") {
    if (!out.cancelled && !out.feedbackText) out.answer = (r as ConfirmResult).confirmed;
  } else if (type === "form") {
    const f = r as QuestionsResult;
    if (f.answers && Object.keys(f.answers).length > 0) out.answer = f.answers;
    if (f.completedCount > 0) out.completedCount = f.completedCount;
  } else if (type === "tweak") {
    const t = r as TweakResult;
    if (t.answers && Object.keys(t.answers).length > 0) out.answer = t.answers;
    if (t.action) out.action = t.action;
    if (t.replayAnimations) out.replayAnimations = true;
  } else {
    // pick + text: same shape
    const answer = (r as ChoiceResult | TextInputResult).answer;
    if (!out.cancelled && answer != null) out.answer = answer;
  }

  return stripNulls(out);
}
