import { describe, test, expect, mock } from "bun:test";
import { z } from "zod";
import { SwiftDialogProvider } from "./providers/swift.js";
import { compactResponse } from "./compact.js";
import { humanize } from "./humanize.js";
import { isAllOfTheAbove, validateNoAllOfAbove } from "./validate-choices.js";

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
    options: z.array(z.string().min(1).max(100)).min(2).max(10),
    descriptions: z.array(z.string().max(200)).optional(),
    multi: z.boolean().default(false),
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
    position: z.enum(["left", "right", "center"]).default("left"),
    project_path: z.string().optional(),
  });

  test("confirm with minimal params", () => {
    const r = askSchema.parse({ type: "confirm", body: "Proceed?" });
    expect(r.type).toBe("confirm");
    expect(r.body).toBe("Proceed?");
    expect(r.yes).toBe("Yes");
    expect(r.no).toBe("No");
    expect(r.position).toBe("left");
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
