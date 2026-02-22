import { readFileSync } from "fs";
import { extname } from "path";
import { splitNumericSuffix, offsetToPosition } from "./resolve-utils.js";

export interface CSSResolveResult {
  line: number;
  column: number;
  expectedText: string;
  current: number;
  unit: string;
}

/** For .svelte files, extract <style> block content and its char offset within the file. */
function extractCSS(content: string, filePath: string): { css: string; startOffset: number } {
  if (extname(filePath) === ".svelte") {
    const m = content.match(/<style[^>]*>([\s\S]*?)<\/style>/);
    if (!m) throw new Error("No <style> block found in Svelte file");
    return { css: m[1], startOffset: content.indexOf(m[1], m.index!) };
  }
  return { css: content, startOffset: 0 };
}

/** Find selector block in CSS. Returns content between { } and its start offset within css string. */
function findSelectorBlock(css: string, selector: string): { contentStart: number; content: string } | null {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const re = new RegExp(`(?:^|[\\s,}])\\s*${escaped}\\s*\\{`, "gm");
  const match = re.exec(css);
  if (!match) return null;

  const braceIdx = css.indexOf("{", match.index);
  let depth = 1;
  let i = braceIdx + 1;
  while (i < css.length && depth > 0) {
    if (css[i] === "{") depth++;
    else if (css[i] === "}") depth--;
    i++;
  }

  return { contentStart: braceIdx + 1, content: css.slice(braceIdx + 1, i - 1) };
}

/** Find a property value token in a CSS block. Returns offset within css string and the token text. */
function findPropertyValue(
  block: string, blockStart: number, property: string, index: number, fn?: string,
): { offset: number; value: string } | null {
  const escaped = property.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const propRe = new RegExp(`(?:^|;|\\s)\\s*${escaped}\\s*:`, "gm");
  const m = propRe.exec(block);
  if (!m) return null;

  const colonEnd = m.index + m[0].length;
  const semiIdx = block.indexOf(";", colonEnd);
  if (semiIdx === -1) return null;

  const fullValue = block.slice(colonEnd, semiIdx).trim();
  const valueStart = block.indexOf(fullValue, colonEnd);

  if (fn) {
    const fnEsc = fn.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const fnRe = new RegExp(`${fnEsc}\\(([^)]+)\\)`);
    const fm = fullValue.match(fnRe);
    if (!fm) return null;
    const args = fm[1].trim().split(/\s*,\s*/);
    const target = args[index] ?? args[0];
    const targetOff = fullValue.indexOf(fm[0]) + fm[0].indexOf(target);
    return { offset: blockStart + valueStart + targetOff, value: target };
  }

  const tokens = fullValue.split(/\s+/);
  if (index >= tokens.length) return null;
  const target = tokens[index];
  let tokenOff = 0;
  for (let t = 0; t < index; t++) {
    tokenOff = fullValue.indexOf(tokens[t], tokenOff) + tokens[t].length;
  }
  tokenOff = fullValue.indexOf(target, tokenOff);

  return { offset: blockStart + valueStart + tokenOff, value: target };
}

/** Resolve a CSS selector+property to file location and parsed value. */
export function resolveCSS(
  filePath: string,
  selector: string,
  property: string,
  options?: { index?: number; fn?: string; content?: string },
): CSSResolveResult {
  const content = options?.content ?? readFileSync(filePath, "utf-8");
  const { css, startOffset } = extractCSS(content, filePath);

  const block = findSelectorBlock(css, selector);
  if (!block) throw new Error(`Selector "${selector}" not found in ${filePath}`);

  const prop = findPropertyValue(block.content, block.contentStart, property, options?.index ?? 0, options?.fn);
  if (!prop) throw new Error(`Property "${property}" not found in selector "${selector}"`);

  const { numeric, unit } = splitNumericSuffix(prop.value);
  const { line, column } = offsetToPosition(content, startOffset + prop.offset);

  return { line, column, expectedText: prop.value, current: numeric, unit };
}
