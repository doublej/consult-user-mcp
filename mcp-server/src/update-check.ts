import { readFile } from "fs/promises";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { homedir } from "os";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const REPO_OWNER = "doublej";
const REPO_NAME = "consult-user-mcp";
const TIMEOUT_MS = 5000;

function versionParts(version: string): number[] {
  return version.split(/[^0-9]+/).filter(Boolean).map(Number);
}

function isNewer(remote: string, current: string): boolean {
  const r = versionParts(remote);
  const c = versionParts(current);
  const len = Math.max(r.length, c.length);
  for (let i = 0; i < len; i++) {
    const rv = r[i] ?? 0;
    const cv = c[i] ?? 0;
    if (rv > cv) return true;
    if (rv < cv) return false;
  }
  return false;
}

async function getAppVersion(): Promise<string | null> {
  // App bundle: dist/ -> ../VERSION
  const bundlePath = join(__dirname, "..", "VERSION");
  // Dev: mcp-server/dist/ -> ../../macos-app/VERSION
  const devPath = join(__dirname, "..", "..", "macos-app", "VERSION");

  for (const path of [bundlePath, devPath]) {
    try {
      return (await readFile(path, "utf-8")).trim();
    } catch {}
  }
  return null;
}

async function isAutoCheckEnabled(): Promise<boolean> {
  const settingsPath = join(
    homedir(),
    "Library",
    "Application Support",
    "ConsultUserMCP",
    "settings.json",
  );
  try {
    const raw = JSON.parse(await readFile(settingsPath, "utf-8"));
    return raw.autoCheckForUpdatesEnabled !== false;
  } catch {
    return true;
  }
}

export interface UpdateResult {
  currentVersion: string;
  remoteVersion: string;
}

export async function checkForUpdate(): Promise<UpdateResult | null> {
  if (!(await isAutoCheckEnabled())) return null;

  const current = await getAppVersion();
  if (!current) return null;

  const url = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest`;
  const res = await fetch(url, {
    headers: { Accept: "application/vnd.github+json" },
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  if (!res.ok) return null;

  const data = (await res.json()) as { tag_name?: string };
  const tag = data.tag_name;
  if (!tag) return null;

  const remote = tag.startsWith("v") ? tag.slice(1) : tag;
  if (!isNewer(remote, current)) return null;

  return { currentVersion: current, remoteVersion: remote };
}
