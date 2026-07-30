import { describe, expect, test } from "bun:test";
import { takeAttachments, attachmentBlocks, type Attachment } from "../src/attachments.js";

const png = (name = "shot.png"): Attachment => ({
  mimeType: "image/png",
  data: "aGVsbG8=",
  width: 800,
  height: 600,
  name,
});

describe("takeAttachments", () => {
  test("returns the list and removes it from the raw response", () => {
    const raw: Record<string, unknown> = { confirmed: true, attachments: [png()] };
    const taken = takeAttachments(raw);

    expect(taken).toHaveLength(1);
    // The base64 must not survive into structuredContent, which is echoed
    // into the transcript as JSON.
    expect("attachments" in raw).toBe(false);
    expect(raw.confirmed).toBe(true);
  });

  test("is a no-op on a response with no attachments", () => {
    const raw: Record<string, unknown> = { confirmed: true };
    expect(takeAttachments(raw)).toEqual([]);
    expect(raw.confirmed).toBe(true);
  });

  test("tolerates junk", () => {
    expect(takeAttachments(null)).toEqual([]);
    expect(takeAttachments("nope")).toEqual([]);
    expect(takeAttachments({ attachments: "nope" })).toEqual([]);
    expect(takeAttachments({ attachments: [{ nope: true }] })).toEqual([]);
  });
});

describe("attachmentBlocks", () => {
  test("returns nothing for an empty list", () => {
    expect(attachmentBlocks([])).toEqual([]);
  });

  test("names the images, then emits one image block each", () => {
    const blocks = attachmentBlocks([png("before.png"), png("after.png")]);

    expect(blocks).toHaveLength(3);
    expect(blocks[0]).toMatchObject({ type: "text" });
    // An image block carries no filename, so the naming line is the only
    // place the agent learns what the person called them.
    expect((blocks[0] as { text: string }).text).toContain("before.png");
    expect((blocks[0] as { text: string }).text).toContain("after.png");
    expect((blocks[0] as { text: string }).text).toContain("800×600");
    expect(blocks[1]).toEqual({ type: "image", data: "aGVsbG8=", mimeType: "image/png" });
    expect(blocks[2]).toEqual({ type: "image", data: "aGVsbG8=", mimeType: "image/png" });
  });

  test("uses the singular for one image", () => {
    const blocks = attachmentBlocks([png()]);
    expect((blocks[0] as { text: string }).text).toContain("attached 1 image:");
  });

  test("describes an unsupported format instead of embedding it", () => {
    const tiff: Attachment = { ...png("scan.tiff"), mimeType: "image/tiff" };
    const blocks = attachmentBlocks([tiff]);

    expect(blocks.every((b) => b.type === "text")).toBe(true);
    expect((blocks[0] as { text: string }).text).toContain("scan.tiff");
    expect((blocks[0] as { text: string }).text).toContain("unsupported");
  });

  test("embeds the supported ones and reports the rest", () => {
    const tiff: Attachment = { ...png("scan.tiff"), mimeType: "image/tiff" };
    const blocks = attachmentBlocks([png("ok.png"), tiff]);

    expect(blocks.filter((b) => b.type === "image")).toHaveLength(1);
    expect((blocks[blocks.length - 1] as { text: string }).text).toContain("scan.tiff");
  });
});
