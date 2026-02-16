const AOTA_PATTERN = /^\s*(all\s+(of\s+the\s+above|the\s+above|of\s+these|options)|select\s+all|everything(\s+above)?|none\s+(of\s+the\s+above|of\s+these))\s*$/i;

export function isAllOfTheAbove(option: string): boolean {
  return AOTA_PATTERN.test(option);
}

export function validateNoAllOfAbove(options: string[]): void {
  const match = options.find(isAllOfTheAbove);
  if (match) {
    throw new Error(
      `Do not include "${match.trim()}" style options. If the user should be able to select multiple answers, set multi: true instead.`,
    );
  }
}
