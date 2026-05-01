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

function formatLocations(filePath: string, results: TextSearchResult[]): string {
  return results.map(r => `${filePath}:${r.line}:${r.column} (value: ${r.expectedText})`).join(", ");
}

/** Resolve a text search pattern with `{v}` placeholder to a unique file location.
 *
 * - Single match → return it.
 * - Multiple matches + `current` provided → pick the unique match whose captured
 *   numeric value equals `current` (float-epsilon tolerance).
 * - Multiple matches + same value → throw with all locations listed.
 * - Multiple matches + no `current` → throw asking for disambiguation. */
export function resolveTextSearch(
  filePath: string,
  search: string,
  options?: { content?: string; current?: number },
): TextSearchResult {
  const parts = search.split("{v}");
  if (parts.length !== 2) throw new Error('Search pattern must contain exactly one "{v}" placeholder');

  const [left, right] = parts;
  const unitMatch = right.match(/^([a-zA-Z%]+)/);
  const unit = unitMatch ? unitMatch[1] : "";

  const pattern = new RegExp(escapeRegExp(left) + "([+-]?\\d*\\.?\\d+)" + escapeRegExp(right), "g");
  const content = options?.content ?? readFileSync(filePath, "utf-8");

  const matches: TextSearchResult[] = [];
  let m: RegExpExecArray | null;
  while ((m = pattern.exec(content)) !== null) {
    const numStr = m[1];
    const valueStart = m.index + left.length;
    const { line, column } = offsetToPosition(content, valueStart);
    matches.push({ line, column, expectedText: numStr + unit, current: parseFloat(numStr), unit });
  }

  if (matches.length === 0) throw new Error(`Pattern "${search}" not found in ${filePath}`);
  if (matches.length === 1) return matches[0];

  if (options?.current === undefined) {
    throw new Error(
      `Pattern "${search}" matched ${matches.length} locations in ${filePath} but no "current" was provided to disambiguate. ` +
      `Locations: ${formatLocations(filePath, matches)}. ` +
      `Pass "current" equal to the value at the intended location, or make 'search' more specific (include surrounding context like a selector or property name).`
    );
  }

  const target = options.current;
  const valueMatches = matches.filter(r => Math.abs(r.current - target) < 1e-9);

  if (valueMatches.length === 0) {
    throw new Error(
      `Pattern "${search}" matched ${matches.length} locations in ${filePath} but none had value ${target}. ` +
      `Found values at: ${formatLocations(filePath, matches)}. ` +
      `Update 'current' to one of the listed values, or make 'search' more specific.`
    );
  }

  if (valueMatches.length > 1) {
    throw new Error(
      `Pattern "${search}" matched ${valueMatches.length} locations in ${filePath} that all share value ${target} (genuinely ambiguous). ` +
      `Locations: ${formatLocations(filePath, valueMatches)}. ` +
      `Make 'search' more specific (include surrounding context like a selector or property name) so it picks a unique location.`
    );
  }

  return valueMatches[0];
}
