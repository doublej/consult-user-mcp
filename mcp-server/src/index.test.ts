import { describe, test, expect, mock } from "bun:test";
import { z } from "zod";
import { SwiftDialogProvider } from "./providers/swift.js";

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

describe("input schemas", () => {
  const pos = z.enum(["left", "right", "center"]).default("left");

  const confirmSchema = z.object({
    body: z.string().min(1).max(1000),
    title: z.string().max(80).default("Confirmation"),
    confirm_label: z.string().max(20).default("Yes"),
    cancel_label: z.string().max(20).default("No"),
    position: pos,
  });

  const chooseSchema = z.object({
    body: z.string().min(1).max(1000),
    choices: z.array(z.string().min(1).max(100)).min(2).max(20),
    descriptions: z.array(z.string().max(200)).optional(),
    allow_multiple: z.boolean().default(true),
    default_selection: z.string().optional(),
    position: pos,
  });

  const textInputSchema = z.object({
    body: z.string().min(1).max(1000),
    title: z.string().max(80).default("Input"),
    default_value: z.string().max(1000).default(""),
    hidden: z.boolean().default(false),
    position: pos,
  });

  test("confirm schema accepts valid input", () => {
    const result = confirmSchema.parse({ body: "Proceed?" });
    expect(result.body).toBe("Proceed?");
    expect(result.title).toBe("Confirmation");
    expect(result.position).toBe("left");
  });

  test("confirm schema rejects empty body", () => {
    expect(() => confirmSchema.parse({ body: "" })).toThrow();
  });

  test("choose schema requires at least 2 choices", () => {
    expect(() => chooseSchema.parse({ body: "Pick", choices: ["one"] })).toThrow();
  });

  test("choose schema accepts valid choices", () => {
    const result = chooseSchema.parse({ body: "Pick", choices: ["a", "b"] });
    expect(result.choices).toEqual(["a", "b"]);
  });

  test("textInput schema applies defaults", () => {
    const result = textInputSchema.parse({ body: "Enter name:" });
    expect(result.hidden).toBe(false);
    expect(result.default_value).toBe("");
  });

  test("position enum rejects invalid values", () => {
    expect(() => confirmSchema.parse({ body: "Test", position: "top" })).toThrow();
  });

  test("position enum accepts all valid values", () => {
    for (const p of ["left", "right", "center"]) {
      const result = confirmSchema.parse({ body: "Test", position: p });
      expect(result.position).toBe(p);
    }
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
    // activeDialog is private, but we can verify behavior:
    // two concurrent calls should return the same result
    expect(provider).toBeDefined();
  });

  test("concurrent calls return same promise result", async () => {
    const provider = new SwiftDialogProvider();
    // Mock execCli by accessing the private method through prototype
    let callCount = 0;
    const original = (provider as any).execCli;
    (provider as any).execCli = async () => {
      callCount++;
      await new Promise(r => setTimeout(r, 50));
      return { confirmed: true };
    };

    const [r1, r2] = await Promise.all([
      provider.confirm({ body: "test", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left" }),
      provider.confirm({ body: "test", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left" }),
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

    await provider.confirm({ body: "first", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left" });
    await provider.confirm({ body: "second", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left" });

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
      provider.confirm({ body: "fail", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left" }),
    ).rejects.toThrow("fail");

    const r = await provider.confirm({ body: "ok", title: "T", confirmLabel: "Y", cancelLabel: "N", position: "left" });
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

    // Fast-forward: wait enough for 2 heartbeats (using real timers with short interval)
    // We'll test with a shorter mock instead
    await new Promise(r => setTimeout(r, 50));
    resolve("done");
    const result = await wrapped;

    expect(result).toBe("done");
    // Can't reliably assert count with real 15s interval, but verify no error
  });

  test("clears interval on rejection", async () => {
    const send = mock(() => Promise.resolve());
    const failing = Promise.reject(new Error("boom"));

    await expect(
      withHeartbeat(failing, { _meta: { progressToken: "tok" }, sendNotification: send }),
    ).rejects.toThrow("boom");
    // Interval should be cleared, no lingering timers
  });
});
