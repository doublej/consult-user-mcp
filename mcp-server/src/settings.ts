import { readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

interface Settings {
  humanizeResponses: boolean;
  reviewBeforeSend: boolean;
}

const defaults: Settings = { humanizeResponses: true, reviewBeforeSend: false };

function settingsPath(): string {
  if (process.platform === "win32") {
    return join(process.env.APPDATA ?? join(homedir(), "AppData", "Roaming"), "ConsultUserMCP", "settings.json");
  }
  return join(homedir(), "Library", "Application Support", "ConsultUserMCP", "settings.json");
}

/** Reads settings from the shared JSON file. Returns defaults on any error. */
export function readSettings(): Settings {
  try {
    const raw = JSON.parse(readFileSync(settingsPath(), "utf-8"));
    return {
      humanizeResponses: raw.humanizeResponses ?? defaults.humanizeResponses,
      reviewBeforeSend: raw.reviewBeforeSend ?? defaults.reviewBeforeSend,
    };
  } catch {
    return { ...defaults };
  }
}
