import { readFileSync } from "fs";
import { offsetToPosition } from "./resolve-utils.js";

export interface TextSearchResult {
  line: number;
  column: number;
  expectedText: string;
  current: number;
  unit: string;
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Resolve a text search pattern with `{v}` placeholder to file location and parsed value. */
export function resolveTextSearch(
  filePath: string,
  search: string,
  options?: { content?: string },
): TextSearchResult {
  const parts = search.split("{v}");
  if (parts.length !== 2) throw new Error('Search pattern must contain exactly one "{v}" placeholder');

  const [left, right] = parts;
  const unitMatch = right.match(/^([a-zA-Z%]+)/);
  const unit = unitMatch ? unitMatch[1] : "";

  const pattern = new RegExp(escapeRegExp(left) + "([+-]?\\d*\\.?\\d+)" + escapeRegExp(right));
  const content = options?.content ?? readFileSync(filePath, "utf-8");
  const match = pattern.exec(content);
  if (!match) throw new Error(`Pattern "${search}" not found in ${filePath}`);

  const numStr = match[1];
  const valueStart = match.index! + left.length;
  const { line, column } = offsetToPosition(content, valueStart);

  return { line, column, expectedText: numStr + unit, current: parseFloat(numStr), unit };
}
