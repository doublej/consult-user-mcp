import type { ConfirmResult, ChoiceResult, TextInputResult, QuestionsResult } from "./types.js";

type AskType = "confirm" | "pick" | "text" | "form";
type RawResult = ConfirmResult | ChoiceResult | TextInputResult | QuestionsResult;

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

  // Feedback takes priority over normal/cancelled
  if (r.feedbackText) return { feedbackText: r.feedbackText };

  // Cancelled/dismissed
  if (r.cancelled || r.dismissed) out.cancelled = true;

  // Type-specific answer extraction
  if (type === "confirm") {
    if (!out.cancelled) out.answer = (r as ConfirmResult).confirmed;
  } else if (type === "form") {
    const f = r as QuestionsResult;
    if (f.answers && Object.keys(f.answers).length > 0) out.answer = f.answers;
    if (f.completedCount > 0) out.completedCount = f.completedCount;
  } else {
    // pick + text: same shape
    const answer = (r as ChoiceResult | TextInputResult).answer;
    if (!out.cancelled && answer != null) out.answer = answer;
  }

  return stripNulls(out);
}
