/** Split "2.5rem" → { numeric: 2.5, unit: "rem" }, "-0.03em" → { numeric: -0.03, unit: "em" } */
export function splitNumericSuffix(text: string): { numeric: number; unit: string } {
  const m = text.match(/^([+-]?\d*\.?\d+)(.*)$/);
  if (!m) throw new Error(`Cannot parse numeric value from "${text}"`);
  return { numeric: parseFloat(m[1]), unit: m[2] };
}

/** Convert character offset to 1-indexed line and column. */
export function offsetToPosition(content: string, offset: number): { line: number; column: number } {
  let line = 1;
  let lastNl = -1;
  for (let i = 0; i < offset; i++) {
    if (content[i] === "\n") { line++; lastNl = i; }
  }
  return { line, column: offset - lastNl };
}
