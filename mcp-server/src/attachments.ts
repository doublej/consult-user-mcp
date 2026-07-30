/**
 * Images the person attached to a dialog, on their way to the agent.
 *
 * The Dialog CLI splices an `attachments` array into its JSON response. This
 * turns that array into MCP image content blocks, which is what makes the
 * agent actually *see* the picture instead of being handed a path to read or a
 * wall of base64 in the structured payload.
 *
 * Two things have to happen and they are easy to get half-right:
 *
 *   - the blocks go in `content`, beside the text result;
 *   - the base64 comes *out* of the structured payload, because
 *     `structuredContent` is echoed into the transcript as JSON and a few
 *     megabytes of it there is both useless and expensive.
 */

/** Formats the Claude API accepts. Anything else is described, not embedded. */
const SUPPORTED = new Set(["image/png", "image/jpeg", "image/gif", "image/webp"]);

export interface Attachment {
  mimeType: string;
  data: string;
  width: number;
  height: number;
  name: string;
}

export interface ImageBlock {
  type: "image";
  data: string;
  mimeType: string;
}

export interface TextBlock {
  type: "text";
  text: string;
}

/** Pulls the attachment list off a raw CLI response, leaving it without one. */
export function takeAttachments(raw: unknown): Attachment[] {
  if (!raw || typeof raw !== "object") return [];
  const holder = raw as { attachments?: unknown };
  const list = holder.attachments;
  delete holder.attachments;
  if (!Array.isArray(list)) return [];

  return list.filter((a): a is Attachment =>
    !!a && typeof a === "object" &&
    typeof (a as Attachment).data === "string" &&
    typeof (a as Attachment).mimeType === "string",
  );
}

/**
 * Content blocks for a set of attachments: one line naming them, then the
 * images themselves.
 *
 * The naming line exists because an image block carries no filename — without
 * it the agent sees pictures with no idea what the person called them or in
 * what order they arrived.
 */
export function attachmentBlocks(attachments: Attachment[]): (TextBlock | ImageBlock)[] {
  if (attachments.length === 0) return [];

  const usable = attachments.filter((a) => SUPPORTED.has(a.mimeType));
  const skipped = attachments.filter((a) => !SUPPORTED.has(a.mimeType));

  const blocks: (TextBlock | ImageBlock)[] = [];
  const described = usable
    .map((a, i) => `${i + 1}. ${a.name} (${a.width}×${a.height})`)
    .join("\n");

  if (usable.length > 0) {
    blocks.push({
      type: "text",
      text: `The user attached ${usable.length} image${usable.length === 1 ? "" : "s"}:\n${described}`,
    });
    for (const a of usable) {
      blocks.push({ type: "image", data: a.data, mimeType: a.mimeType });
    }
  }

  if (skipped.length > 0) {
    blocks.push({
      type: "text",
      text: `Could not attach ${skipped.map((a) => `${a.name} (${a.mimeType})`).join(", ")} — unsupported image format.`,
    });
  }

  return blocks;
}
