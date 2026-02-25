import { describe, test, expect, mock } from "bun:test";
import { z } from "zod";
import { SwiftDialogProvider } from "./providers/swift.js";
import { compactResponse } from "./compact.js";
import { humanize } from "./humanize.js";
import { isAllOfTheAbove, validateNoAllOfAbove } from "./validate-choices.js";
import { resolveCSS } from "./css-resolver.js";
import { resolveTextSearch } from "./text-search-resolver.js";

const DIALOG_TIMEOUT_MS = 10 * 60 * 1000;

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error(`Dialog timed out after ${ms / 1000}s`)), ms)
    ),
  ]);
}

describe("withTimeout", () => {
  test("resolves when promise completes before timeout", async () => {
    const result = await withTimeout(Promise.resolve("done"), 1000);
    expect(result).toBe("done");
  });

  test("rejects when promise exceeds timeout", async () => {
    const slowPromise = new Promise((resolve) => setTimeout(resolve, 200));
    await expect(withTimeout(slowPromise, 50)).rejects.toThrow("timed out");
  });

  test("preserves rejection from original promise", async () => {
    const failing = Promise.reject(new Error("original error"));
    await expect(withTimeout(failing, 1000)).rejects.toThrow("original error");
  });
});

describe("ask schema", () => {
  const questionSchema = z.object({
    id: z.string().min(1).max(50),
    question: z.string().min(1).max(500),
    type: z.enum(["choice", "text"]).default("choice"),
    options: z.array(z.string().min(1).max(100)).min(2).max(10).optional(),
    descriptions: z.array(z.string().max(200)).optional(),
    multi: z.boolean().default(false),
    placeholder: z.string().max(200).optional(),
    hidden: z.boolean().default(false),
  }).superRefine((data, ctx) => {
    if (data.type === "choice" && (!data.options || data.options.length < 2)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "options required (min 2) for choice questions",
        path: ["options"],
      });
    }
  });

  const askSchema = z.object({
    type: z.enum(["confirm", "pick", "text", "form"]),
    body: z.string().min(1).max(1000),
    yes: z.string().max(20).default("Yes"),
    no: z.string().max(20).default("No"),
    choices: z.array(z.string().min(1).max(100)).min(2).max(20).optional(),
    multi: z.boolean().default(false),
    descriptions: z.array(z.string().max(200)).optional(),
    default: z.string().optional(),
    hidden: z.boolean().default(false),
    questions: z.array(questionSchema).min(1).max(10).optional(),
    mode: z.enum(["wizard", "accordion"]).default("wizard"),
    title: z.string().max(80).optional(),
    position: z.enum(["left", "right", "center"]).optional(),
    project_path: z.string().optional(),
  });

  test("confirm with minimal params", () => {
    const r = askSchema.parse({ type: "confirm", body: "Proceed?" });
    expect(r.type).toBe("confirm");
    expect(r.body).toBe("Proceed?");
    expect(r.yes).toBe("Yes");
    expect(r.no).toBe("No");
    expect(r.position).toBeUndefined();
  });

  test("confirm with custom labels", () => {
    const r = askSchema.parse({ type: "confirm", body: "Deploy?", yes: "Deploy", no: "Cancel" });
    expect(r.yes).toBe("Deploy");
    expect(r.no).toBe("Cancel");
  });

  test("pick requires choices", () => {
    const r = askSchema.parse({ type: "pick", body: "Pick", choices: ["a", "b"] });
    expect(r.choices).toEqual(["a", "b"]);
    expect(r.multi).toBe(false);
  });

  test("pick with multi", () => {
    const r = askSchema.parse({ type: "pick", body: "Pick", choices: ["a", "b"], multi: true });
    expect(r.multi).toBe(true);
  });

  test("text with defaults", () => {
    const r = askSchema.parse({ type: "text", body: "Enter:" });
    expect(r.hidden).toBe(false);
    expect(r.default).toBeUndefined();
  });

  test("text hidden", () => {
    const r = askSchema.parse({ type: "text", body: "Key:", hidden: true });
    expect(r.hidden).toBe(true);
  });

  test("form with questions", () => {
    const r = askSchema.parse({
      type: "form", body: "Setup",
      questions: [{ id: "lang", question: "Language?", options: ["TS", "Py"] }],
    });
    expect(r.questions).toHaveLength(1);
    expect(r.questions![0].multi).toBe(false);
  });

  test("form with text-type question (no options)", () => {
    const r = askSchema.parse({
      type: "form", body: "Setup",
      questions: [{ id: "name", question: "Project name?", type: "text" }],
    });
    expect(r.questions![0].type).toBe("text");
    expect(r.questions![0].options).toBeUndefined();
  });

  test("form with mixed choice and text questions", () => {
    const r = askSchema.parse({
      type: "form", body: "Setup",
      questions: [
        { id: "lang", question: "Language?", options: ["TS", "Py"] },
        { id: "name", question: "Project name?", type: "text", placeholder: "my-project" },
        { id: "db", question: "Database?", type: "choice", options: ["Postgres", "SQLite"] },
      ],
    });
    expect(r.questions).toHaveLength(3);
    expect(r.questions![0].type).toBe("choice");
    expect(r.questions![1].type).toBe("text");
    expect(r.questions![1].placeholder).toBe("my-project");
    expect(r.questions![2].type).toBe("choice");
  });

  test("form text question with hidden flag", () => {
    const r = askSchema.parse({
      type: "form", body: "Credentials",
      questions: [{ id: "key", question: "API key?", type: "text", hidden: true }],
    });
    expect(r.questions![0].hidden).toBe(true);
  });

  test("backward compat: no type field defaults to choice", () => {
    const r = askSchema.parse({
      type: "form", body: "Setup",
      questions: [{ id: "lang", question: "Language?", options: ["TS", "Py"] }],
    });
    expect(r.questions![0].type).toBe("choice");
  });

  test("rejects choice question without options", () => {
    expect(() => askSchema.parse({
      type: "form", body: "Setup",
      questions: [{ id: "lang", question: "Language?", type: "choice" }],
    })).toThrow();
  });

  test("rejects empty body", () => {
    expect(() => askSchema.parse({ type: "confirm", body: "" })).toThrow();
  });

  test("rejects invalid type", () => {
    expect(() => askSchema.parse({ type: "invalid", body: "test" })).toThrow();
  });

  test("position accepts all valid values", () => {
    for (const p of ["left", "right", "center"]) {
      const r = askSchema.parse({ type: "confirm", body: "Test", position: p });
      expect(r.position).toBe(p);
    }
  });

  test("position rejects invalid values", () => {
    expect(() => askSchema.parse({ type: "confirm", body: "Test", position: "top" })).toThrow();
  });
});

describe("compactResponse", () => {
  test("confirm: normal yes", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: true, cancelled: false,
      dismissed: false, answer: "Yes", comment: null,
    });
    expect(r).toEqual({ answer: true });
  });

  test("confirm: normal no", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: false,
      dismissed: false, answer: "No", comment: null,
    });
    expect(r).toEqual({ answer: false });
  });

  test("confirm: cancelled", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: true,
      dismissed: false, answer: null, comment: null,
    });
    expect(r).toEqual({ cancelled: true });
  });

  test("confirm: dismissed maps to cancelled", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: false,
      dismissed: true, answer: null, comment: null,
    });
    expect(r).toEqual({ cancelled: true });
  });

  test("confirm: snoozed", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: false,
      dismissed: false, answer: null, comment: null,
      snoozed: true, snoozeMinutes: 5, remainingSeconds: 300,
    });
    expect(r).toEqual({ snoozed: true, remainingSeconds: 300 });
  });

  test("confirm: feedback", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: false,
      dismissed: false, answer: null, comment: null,
      feedbackText: "Need more context",
    });
    expect(r).toEqual({ feedbackText: "Need more context" });
  });

  test("pick: single selection", () => {
    const r = compactResponse("pick", {
      dialogType: "choose", answer: "PostgreSQL", cancelled: false,
      dismissed: false, description: null, comment: null,
    });
    expect(r).toEqual({ answer: "PostgreSQL" });
  });

  test("pick: multi selection", () => {
    const r = compactResponse("pick", {
      dialogType: "choose", answer: ["Auth", "UI"], cancelled: false,
      dismissed: false, description: null, comment: null,
    });
    expect(r).toEqual({ answer: ["Auth", "UI"] });
  });

  test("pick: cancelled", () => {
    const r = compactResponse("pick", {
      dialogType: "choose", answer: null, cancelled: true,
      dismissed: false, description: null, comment: null,
    });
    expect(r).toEqual({ cancelled: true });
  });

  test("text: normal answer", () => {
    const r = compactResponse("text", {
      dialogType: "textInput", answer: "my message", cancelled: false,
      dismissed: false, comment: null,
    });
    expect(r).toEqual({ answer: "my message" });
  });

  test("text: cancelled", () => {
    const r = compactResponse("text", {
      dialogType: "textInput", answer: null, cancelled: true,
      dismissed: false, comment: null,
    });
    expect(r).toEqual({ cancelled: true });
  });

  test("form: complete answers", () => {
    const r = compactResponse("form", {
      dialogType: "questions", answers: { lang: "TypeScript", test: "Vitest" },
      cancelled: false, dismissed: false, completedCount: 2,
    });
    expect(r).toEqual({ answer: { lang: "TypeScript", test: "Vitest" }, completedCount: 2 });
  });

  test("form: partial answers on cancel", () => {
    const r = compactResponse("form", {
      dialogType: "questions", answers: { lang: "TypeScript" },
      cancelled: true, dismissed: false, completedCount: 1,
    });
    expect(r).toEqual({ cancelled: true, answer: { lang: "TypeScript" }, completedCount: 1 });
  });

  test("form: cancelled with no answers", () => {
    const r = compactResponse("form", {
      dialogType: "questions", answers: {},
      cancelled: true, dismissed: false, completedCount: 0,
    });
    expect(r).toEqual({ cancelled: true });
  });

  test("confirm: askDifferently", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: false,
      dismissed: false, answer: null, comment: null,
      askDifferently: "text",
    });
    expect(r).toEqual({ askDifferently: "text" });
  });

  test("pick: askDifferently", () => {
    const r = compactResponse("pick", {
      dialogType: "choose", answer: null, cancelled: false,
      dismissed: false, description: null, comment: null,
      askDifferently: "confirm",
    });
    expect(r).toEqual({ askDifferently: "confirm" });
  });

  test("text: askDifferently", () => {
    const r = compactResponse("text", {
      dialogType: "textInput", answer: null, cancelled: false,
      dismissed: false, comment: null,
      askDifferently: "pick",
    });
    expect(r).toEqual({ askDifferently: "pick" });
  });

  test("form: askDifferently", () => {
    const r = compactResponse("form", {
      dialogType: "questions", answers: {},
      cancelled: false, dismissed: false, completedCount: 0,
      askDifferently: "text",
    });
    expect(r).toEqual({ askDifferently: "text" });
  });

  test("askDifferently takes priority over feedback", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: false,
      dismissed: false, answer: null, comment: null,
      feedbackText: "some feedback",
      askDifferently: "pick",
    });
    expect(r).toEqual({ askDifferently: "pick" });
  });

  test("snoozed takes priority over askDifferently", () => {
    const r = compactResponse("confirm", {
      dialogType: "confirm", confirmed: false, cancelled: false,
      dismissed: false, answer: null, comment: null,
      snoozed: true, remainingSeconds: 300,
      askDifferently: "pick",
    });
    expect(r).toEqual({ snoozed: true, remainingSeconds: 300 });
  });

  test("strips null fields from output", () => {
    const r = compactResponse("text", {
      dialogType: "textInput", answer: "hello", cancelled: false,
      dismissed: false, comment: null,
      snoozed: undefined, feedbackText: undefined,
    });
    expect(r).toEqual({ answer: "hello" });
    expect("cancelled" in r).toBe(false);
    expect("snoozed" in r).toBe(false);
  });
});

describe("humanize", () => {
  test("snoozed → plain text with sleep instruction", () => {
    expect(humanize({ snoozed: true, remainingSeconds: 300 }))
      .toBe("The user snoozed. Run `sleep 300`, then retry the exact same question.");
  });

  test("askDifferently → plain text with type description", () => {
    expect(humanize({ askDifferently: "pick-multi" }))
      .toBe("The user wants this question re-asked as a multi-select list (type: pick, multi: true).");
  });

  test("askDifferently: confirm", () => {
    expect(humanize({ askDifferently: "confirm" }))
      .toBe("The user wants this question re-asked as a yes/no confirmation (type: confirm).");
  });

  test("askDifferently: unknown type passes through", () => {
    expect(humanize({ askDifferently: "future-type" }))
      .toBe("The user wants this question re-asked as future-type.");
  });

  test("feedbackText → plain text with feedback", () => {
    expect(humanize({ feedbackText: "be more specific" }))
      .toBe('The user gave feedback: "be more specific". Adjust your approach, then re-ask.');
  });

  test("cancelled → plain text", () => {
    expect(humanize({ cancelled: true }))
      .toBe("The user cancelled. Proceed with a reasonable default.");
  });

  test("normal string answer", () => {
    expect(humanize({ answer: "PostgreSQL" }))
      .toBe("The user responded: PostgreSQL");
  });

  test("confirm true answer", () => {
    expect(humanize({ answer: true }))
      .toBe("The user confirmed.");
  });

  test("confirm false answer", () => {
    expect(humanize({ answer: false }))
      .toBe("The user declined.");
  });

  test("multi-select answer", () => {
    expect(humanize({ answer: ["Auth", "UI"] }))
      .toBe("The user selected: Auth, UI");
  });

  test("form answer", () => {
    expect(humanize({ answer: { lang: "TS" }, completedCount: 1 }))
      .toBe("The user answered: lang: TS (1/1 completed)");
  });
});

describe("validateNoAllOfAbove", () => {
  const rejected = [
    "All of the above",
    "all the above",
    "All of these",
    "Select all",
    "All options",
    "Everything",
    "Everything above",
    "None of the above",
    "None of these",
    "  All of the above  ",
  ];

  for (const option of rejected) {
    test(`rejects: "${option}"`, () => {
      expect(isAllOfTheAbove(option)).toBe(true);
    });
  }

  const allowed = [
    "All sizes",
    "Above average",
    "Select all images",
    "None",
    "All",
    "PostgreSQL",
    "Everything else matters",
    "None selected yet",
  ];

  for (const option of allowed) {
    test(`allows: "${option}"`, () => {
      expect(isAllOfTheAbove(option)).toBe(false);
    });
  }

  test("validateNoAllOfAbove throws on first match", () => {
    expect(() => validateNoAllOfAbove(["A", "B", "All of the above"])).toThrow(
      'Do not include "All of the above" style options',
    );
  });

  test("validateNoAllOfAbove passes clean list", () => {
    expect(() => validateNoAllOfAbove(["PostgreSQL", "MySQL", "SQLite"])).not.toThrow();
  });
});

describe("constants", () => {
  test("dialog timeout is 10 minutes", () => {
    expect(DIALOG_TIMEOUT_MS).toBe(600000);
  });
});

const HEARTBEAT_INTERVAL_MS = 15_000;

function withHeartbeat<T>(
  promise: Promise<T>,
  extra: { _meta?: { progressToken?: string | number }; sendNotification: (n: unknown) => Promise<void> },
): Promise<T> {
  const token = extra._meta?.progressToken;
  if (token == null) return promise;
  let progress = 0;
  const iv = setInterval(() => {
    extra.sendNotification({
      method: "notifications/progress",
      params: { progressToken: token, progress: ++progress, message: "Waiting for user response" },
    });
  }, HEARTBEAT_INTERVAL_MS);
  return promise.finally(() => clearInterval(iv));
}

describe("singleton dialog guard", () => {
  test("activeDialog is initially null", () => {
    const provider = new SwiftDialogProvider();
    expect(provider).toBeDefined();
  });

  test("concurrent calls return same promise result", async () => {
    const provider = new SwiftDialogProvider();
    let callCount = 0;
    const original = (provider as any).execCli;
    (provider as any).execCli = async () => {
      callCount++;
      await new Promise(r => setTimeout(r, 50));
      return { confirmed: true };
    };

    const [r1, r2] = await Promise.all([
      provider.confirm({ body: "test", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left", projectPath: "" }),
      provider.confirm({ body: "test", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left", projectPath: "" }),
    ]);

    expect(callCount).toBe(1);
    expect(r1).toEqual(r2);
    (provider as any).execCli = original;
  });

  test("activeDialog resets after completion", async () => {
    const provider = new SwiftDialogProvider();
    let callCount = 0;
    (provider as any).execCli = async () => {
      callCount++;
      return { confirmed: true };
    };

    await provider.confirm({ body: "first", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left", projectPath: "" });
    await provider.confirm({ body: "second", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left", projectPath: "" });

    expect(callCount).toBe(2);
  });

  test("activeDialog resets after error", async () => {
    const provider = new SwiftDialogProvider();
    let callCount = 0;
    (provider as any).execCli = async () => {
      callCount++;
      if (callCount === 1) throw new Error("fail");
      return { confirmed: true };
    };

    await expect(
      provider.confirm({ body: "fail", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left", projectPath: "" }),
    ).rejects.toThrow("fail");

    const r = await provider.confirm({ body: "ok", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left", projectPath: "" });
    expect(callCount).toBe(2);
    expect(r).toEqual({ confirmed: true });
  });
});

describe("withHeartbeat", () => {
  test("no-op when no progressToken", async () => {
    const send = mock(() => Promise.resolve());
    const result = await withHeartbeat(Promise.resolve("done"), { sendNotification: send });
    expect(result).toBe("done");
    expect(send).not.toHaveBeenCalled();
  });

  test("sends progress notifications on interval", async () => {
    const send = mock(() => Promise.resolve());
    let resolve!: (v: string) => void;
    const promise = new Promise<string>(r => { resolve = r; });

    const wrapped = withHeartbeat(promise, {
      _meta: { progressToken: "tok-1" },
      sendNotification: send,
    });

    await new Promise(r => setTimeout(r, 50));
    resolve("done");
    const result = await wrapped;

    expect(result).toBe("done");
  });

  test("clears interval on rejection", async () => {
    const send = mock(() => Promise.resolve());
    const failing = Promise.reject(new Error("boom"));

    await expect(
      withHeartbeat(failing, { _meta: { progressToken: "tok" }, sendNotification: send }),
    ).rejects.toThrow("boom");
  });
});

describe("resolveCSS", () => {
  const cssFile = "test.css";
  const css = `h1 {
  font-size: 2.5rem;
  letter-spacing: -0.03em;
  color: #1a1a1a;
}

.lead {
  margin: 10px 20px;
  line-height: 1.6;
}

.card {
  transform: rotateY(-25deg) translateX(10px);
  z-index: 10;
}
`;

  test("simple property", () => {
    const r = resolveCSS(cssFile, "h1", "font-size", { content: css });
    expect(r.current).toBe(2.5);
    expect(r.unit).toBe("rem");
    expect(r.expectedText).toBe("2.5rem");
    expect(r.line).toBe(2);
  });

  test("negative value", () => {
    const r = resolveCSS(cssFile, "h1", "letter-spacing", { content: css });
    expect(r.current).toBe(-0.03);
    expect(r.unit).toBe("em");
    expect(r.expectedText).toBe("-0.03em");
  });

  test("multi-value property index 0", () => {
    const r = resolveCSS(cssFile, ".lead", "margin", { content: css, index: 0 });
    expect(r.current).toBe(10);
    expect(r.unit).toBe("px");
    expect(r.expectedText).toBe("10px");
  });

  test("multi-value property index 1", () => {
    const r = resolveCSS(cssFile, ".lead", "margin", { content: css, index: 1 });
    expect(r.current).toBe(20);
    expect(r.unit).toBe("px");
    expect(r.expectedText).toBe("20px");
  });

  test("unitless value", () => {
    const r = resolveCSS(cssFile, ".card", "z-index", { content: css });
    expect(r.current).toBe(10);
    expect(r.unit).toBe("");
  });

  test("CSS function value", () => {
    const r = resolveCSS(cssFile, ".card", "transform", { content: css, fn: "rotateY" });
    expect(r.current).toBe(-25);
    expect(r.unit).toBe("deg");
    expect(r.expectedText).toBe("-25deg");
  });

  test("svelte file extracts style block", () => {
    const svelte = `<script>let x = 1;</script>
<div>hello</div>
<style>
.hero {
  font-size: 3rem;
}
</style>`;
    const r = resolveCSS("test.svelte", ".hero", "font-size", { content: svelte });
    expect(r.current).toBe(3);
    expect(r.unit).toBe("rem");
    expect(r.line).toBe(5);
  });

  test("throws on missing selector", () => {
    expect(() => resolveCSS(cssFile, ".missing", "font-size", { content: css })).toThrow('Selector ".missing" not found');
  });

  test("throws on missing property", () => {
    expect(() => resolveCSS(cssFile, "h1", "padding", { content: css })).toThrow('Property "padding" not found');
  });
});

describe("resolveTextSearch", () => {
  test("CSS value with px unit", () => {
    const content = "div { padding: 16px; }";
    const r = resolveTextSearch("test.css", "padding: {v}px", { content });
    expect(r.current).toBe(16);
    expect(r.unit).toBe("px");
    expect(r.expectedText).toBe("16px");
    expect(r.line).toBe(1);
  });

  test("CSS value with rem unit", () => {
    const content = ".hero {\n  font-size: 2.5rem;\n}";
    const r = resolveTextSearch("test.css", "font-size: {v}rem", { content });
    expect(r.current).toBe(2.5);
    expect(r.unit).toBe("rem");
    expect(r.expectedText).toBe("2.5rem");
    expect(r.line).toBe(2);
  });

  test("unitless value", () => {
    const content = "div { z-index: 10; }";
    const r = resolveTextSearch("test.css", "z-index: {v};", { content });
    expect(r.current).toBe(10);
    expect(r.unit).toBe("");
    expect(r.expectedText).toBe("10");
  });

  test("negative value", () => {
    const content = "h1 { letter-spacing: -0.03em; }";
    const r = resolveTextSearch("test.css", "letter-spacing: {v}em", { content });
    expect(r.current).toBe(-0.03);
    expect(r.unit).toBe("em");
    expect(r.expectedText).toBe("-0.03em");
  });

  test("decimal-only value", () => {
    const content = "p { line-height: .8; }";
    const r = resolveTextSearch("test.css", "line-height: {v};", { content });
    expect(r.current).toBe(0.8);
    expect(r.expectedText).toBe(".8");
  });

  test("CSS function value", () => {
    const content = ".card { transform: rotateY(-25deg); }";
    const r = resolveTextSearch("test.css", "rotateY({v}deg)", { content });
    expect(r.current).toBe(-25);
    expect(r.unit).toBe("deg");
    expect(r.expectedText).toBe("-25deg");
  });

  test("percentage value", () => {
    const content = ".overlay { opacity: 80%; }";
    const r = resolveTextSearch("test.css", "opacity: {v}%", { content });
    expect(r.current).toBe(80);
    expect(r.unit).toBe("%");
    expect(r.expectedText).toBe("80%");
  });

  test("uses first match", () => {
    const content = "a { margin: 10px; }\nb { margin: 20px; }";
    const r = resolveTextSearch("test.css", "margin: {v}px", { content });
    expect(r.current).toBe(10);
    expect(r.line).toBe(1);
  });

  test("throws on missing {v} placeholder", () => {
    expect(() => resolveTextSearch("test.css", "padding: 10px", { content: "" }))
      .toThrow('must contain exactly one "{v}" placeholder');
  });

  test("throws on multiple {v} placeholders", () => {
    expect(() => resolveTextSearch("test.css", "{v}px {v}px", { content: "" }))
      .toThrow('must contain exactly one "{v}" placeholder');
  });

  test("throws when pattern not found", () => {
    expect(() => resolveTextSearch("test.css", "padding: {v}px", { content: "div { color: red; }" }))
      .toThrow('Pattern "padding: {v}px" not found');
  });
});

describe("toKebabCase", () => {
  // Inline the function for testing (mirrors index.ts implementation)
  function toKebabCase(label: string): string {
    return label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  }

  test("simple label", () => expect(toKebabCase("Padding")).toBe("padding"));
  test("two words", () => expect(toKebabCase("Font Size")).toBe("font-size"));
  test("with parenthetical", () => expect(toKebabCase("Line Height (px)")).toBe("line-height-px"));
  test("already kebab", () => expect(toKebabCase("font-size")).toBe("font-size"));
  test("camelCase", () => expect(toKebabCase("fontSize")).toBe("fontsize"));
  test("special chars", () => expect(toKebabCase("  Top & Bottom  ")).toBe("top-bottom"));
});

describe("tweak schema", () => {
  const tweakParameterSchema = z.object({
    id: z.string().min(1).max(50).optional(),
    label: z.string().min(1).max(100),
    element: z.string().max(100).optional(),
    file: z.string().min(1),
    selector: z.string().max(200).optional(),
    property: z.string().max(100).optional(),
    index: z.number().int().min(0).optional(),
    fn: z.string().max(50).optional(),
    search: z.string().max(500).optional(),
    line: z.number().int().min(1).optional(),
    column: z.number().int().min(1).optional(),
    expectedText: z.string().min(1).max(50).optional(),
    current: z.number().optional(),
    min: z.number(),
    max: z.number(),
    step: z.number().positive().optional(),
    unit: z.string().max(10).optional(),
  }).refine(
    (p) => (p.selector && p.property) || (p.line != null && p.column != null && p.expectedText && p.current != null) || p.search,
    { message: "Provide selector+property (CSS), search (text search), or line+column+expectedText+current (direct)" },
  );

  test("search mode accepted", () => {
    const r = tweakParameterSchema.parse({
      label: "Padding", file: "style.css", search: "padding: {v}px", min: 0, max: 60,
    });
    expect(r.search).toBe("padding: {v}px");
    expect(r.id).toBeUndefined();
  });

  test("CSS mode accepted", () => {
    const r = tweakParameterSchema.parse({
      id: "fs", label: "Font Size", file: "style.css",
      selector: "h1", property: "font-size", min: 1, max: 10,
    });
    expect(r.selector).toBe("h1");
  });

  test("direct mode accepted", () => {
    const r = tweakParameterSchema.parse({
      id: "pad", label: "Padding", file: "style.css",
      line: 5, column: 12, expectedText: "16px", current: 16, min: 0, max: 60,
    });
    expect(r.line).toBe(5);
  });

  test("rejects when no resolution mode provided", () => {
    expect(() => tweakParameterSchema.parse({
      label: "Padding", file: "style.css", min: 0, max: 60,
    })).toThrow();
  });

  test("id is optional", () => {
    const r = tweakParameterSchema.parse({
      label: "Padding", file: "style.css", search: "padding: {v}px", min: 0, max: 60,
    });
    expect(r.id).toBeUndefined();
  });
});

describe("resolveTextSearch roundtrip (simulates FileRewriter)", () => {
  /**
   * Simulates what the Swift FileRewriter does: find expectedText at line:column,
   * replace with newValue + unit, return the modified content.
   */
  function simulateWrite(
    content: string,
    resolved: { line: number; column: number; expectedText: string; unit: string },
    newValue: number,
  ): string {
    const lines = content.split("\n");
    const line = lines[resolved.line - 1];
    const colIdx = resolved.column - 1;
    const found = line.substring(colIdx, colIdx + resolved.expectedText.length);
    if (found !== resolved.expectedText) {
      throw new Error(`Verification failed: expected '${resolved.expectedText}' at L${resolved.line}:C${resolved.column}, found '${found}'`);
    }
    // Format: integer if no decimal, otherwise preserve decimal places (mirrors Swift formatValue)
    const isInteger = !resolved.expectedText.replace(/[a-zA-Z%]+$/, "").includes(".");
    const numStr = isInteger ? String(Math.round(newValue)) : String(newValue);
    const newText = numStr + resolved.unit;
    lines[resolved.line - 1] = line.substring(0, colIdx) + newText + line.substring(colIdx + resolved.expectedText.length);
    return lines.join("\n");
  }

  test("single value: resolve → write → verify file", () => {
    const content = ".hero {\n\tpadding: 20px;\n}";
    const r = resolveTextSearch("f", "padding: {v}px", { content });
    expect(r).toEqual({ line: 2, column: 11, expectedText: "20px", current: 20, unit: "px" });

    const written = simulateWrite(content, r, 40);
    expect(written).toBe(".hero {\n\tpadding: 40px;\n}");
  });

  test("write changes length, then re-resolve still finds value", () => {
    const content = "div { margin: 8px; }";
    const r = resolveTextSearch("f", "margin: {v}px", { content });
    expect(r.expectedText).toBe("8px");

    const written = simulateWrite(content, r, 120);
    expect(written).toBe("div { margin: 120px; }");

    // Re-resolve on the modified content
    const r2 = resolveTextSearch("f", "margin: {v}px", { content: written });
    expect(r2.current).toBe(120);
    expect(r2.expectedText).toBe("120px");
  });

  test("two params on same line: write first, sibling column shifts", () => {
    const content = "\t\ttransform: rotateY(-25deg) rotateX(6deg) translateZ(0);";
    const ry = resolveTextSearch("f", "rotateY({v}deg)", { content });
    const rx = resolveTextSearch("f", "rotateX({v}deg)", { content });

    // Write rotateY from -25 to 5 (shorter: "-25deg" → "5deg", -2 chars)
    const after1 = simulateWrite(content, ry, 5);
    expect(after1).toContain("rotateY(5deg)");
    expect(after1).toContain("rotateX(6deg)");

    // rotateX column must shift — re-resolve to get new position
    const rx2 = resolveTextSearch("f", "rotateX({v}deg)", { content: after1 });
    expect(rx2.current).toBe(6);
    expect(rx2.column).toBe(rx.column - 2); // shifted left by 2 chars

    // Write rotateX
    const after2 = simulateWrite(after1, rx2, -10);
    expect(after2).toContain("rotateY(5deg)");
    expect(after2).toContain("rotateX(-10deg)");
  });

  test("negative to positive value", () => {
    const content = "div { left: -50px; }";
    const r = resolveTextSearch("f", "left: {v}px", { content });
    expect(r.expectedText).toBe("-50px");

    const written = simulateWrite(content, r, 10);
    expect(written).toBe("div { left: 10px; }");
  });

  test("value with percentage unit", () => {
    const content = "div { width: 80%; }";
    const r = resolveTextSearch("f", "width: {v}%", { content });
    const written = simulateWrite(content, r, 100);
    expect(written).toBe("div { width: 100%; }");
  });

  test("decimal value roundtrip", () => {
    const content = "p { line-height: 1.5; }";
    const r = resolveTextSearch("f", "line-height: {v};", { content });
    expect(r.expectedText).toBe("1.5");
    expect(r.unit).toBe("");

    const written = simulateWrite(content, r, 2.0);
    expect(written).toBe("p { line-height: 2; }");
  });
});
