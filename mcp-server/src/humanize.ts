/** Maps askDifferently identifiers to natural-language re-ask instructions. */
const askDifferentlyMap: Record<string, string> = {
  "confirm": "a yes/no confirmation (type: confirm)",
  "pick": "a single-select list (type: pick)",
  "pick-multi": "a multi-select list (type: pick, multi: true)",
  "text": "a text input (type: text)",
  "text-hidden": "a password input (type: text, hidden: true)",
  "form-wizard": "a step-by-step wizard (type: form, mode: wizard)",
  "form-accordion": "an accordion form (type: form, mode: accordion)",
};

function formatAnswer(answer: unknown, completedCount?: number): string {
  if (typeof answer === "boolean") return answer ? "The user confirmed." : "The user declined.";
  if (typeof answer === "string") return `The user responded: ${answer}`;
  if (Array.isArray(answer)) return `The user selected: ${answer.join(", ")}`;
  if (typeof answer === "object" && answer !== null) {
    const entries = Object.entries(answer as Record<string, unknown>);
    const parts = entries.map(([k, v]) => `${k}: ${v}`);
    const suffix = completedCount != null ? ` (${completedCount}/${entries.length} completed)` : "";
    return `The user answered: ${parts.join(", ")}${suffix}`;
  }
  return `The user responded: ${String(answer)}`;
}

/**
 * Central gateway that converts compact responses into plain-text.
 * Every response becomes a human-readable string — no JSON for the LLM to parse.
 */
export function humanize(compact: Record<string, unknown>): string {
  if (compact.snoozed) {
    const seconds = compact.remainingSeconds ?? 60;
    return `The user snoozed. Run \`sleep ${seconds}\`, then retry the exact same question.`;
  }

  if (compact.askDifferently) {
    const desc = askDifferentlyMap[compact.askDifferently as string] ?? String(compact.askDifferently);
    return `The user wants this question re-asked as ${desc}.`;
  }

  if (compact.feedbackText) {
    return `The user gave feedback: "${compact.feedbackText}". Adjust your approach, then re-ask.`;
  }

  if (compact.cancelled) {
    return "The user cancelled. Proceed with a reasonable default.";
  }

  return formatAnswer(compact.answer, compact.completedCount as number | undefined);
}
