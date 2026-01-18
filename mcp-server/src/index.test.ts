import { describe, test, expect } from "bun:test";
import { z } from "zod";

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
