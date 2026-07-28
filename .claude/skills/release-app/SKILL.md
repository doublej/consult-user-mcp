---
name: release-app
description: Cut a macOS or Windows release of Consult User MCP — version files, releases.json, generated changelog, tag, GitHub release with assets. Use when asked to "release", "cut a release", "ship a version", "tag a release", or "publish an update" for this project. Covers both platforms and the baseprompt-version gate.
---

# Release Consult User MCP

Two platforms, two procedures. They share `docs/src/lib/data/releases.json` as the single source of truth.

**Never run `gh release create` without attaching assets.** A release with no assets breaks the auto-updater for everyone already on the previous version.

## macOS

Runs entirely on this machine.

1. Update `macos-app/VERSION`.
2. If `macos-app/Sources/Resources/base-prompt.md` changed, bump its version comment (first line). See `.claude/rules/baseprompt.md`.
3. Add the release entry to `docs/src/lib/data/releases.json`. Write user-facing benefits, not commit messages — see `.claude/rules/release-notes.md`.
4. `bun run changelog` — regenerates `CHANGELOG.md`. Never hand-edit it.
5. `bash scripts/validate-baseprompt-version.sh`.
6. Commit everything.
7. `bash scripts/release.sh --platform macos` — builds, zips, tags, creates the GitHub release.

`--dry-run` validates preconditions without executing. Use it first when anything about the state is uncertain.

## Windows

.NET, WPF, and Velopack all require a real Windows environment. Steps 2–3 cannot run here.

**On macOS:**

1. Update `windows-app/VERSION`, add the entry to `releases.json`, `bun run changelog`, commit, push.

**On the Windows box** (`ssh user@192.168.178.197`, repo at `C:\Users\jurre\PycharmProjects\consult-user-mcp`):

2. Build the installer:
   ```
   git checkout main && git pull
   powershell -ExecutionPolicy Bypass -File scripts\build-windows-installer.ps1
   ```
3. Tag and release from there, since `gh` is authenticated and the assets are local:
   ```
   git tag windows/vX.Y.Z HEAD && git push origin windows/vX.Y.Z
   gh release create windows/vX.Y.Z --title "Windows vX.Y.Z — ..." --notes "..." releases/windows/*
   ```

Full Windows toolchain details and gotchas: `.claude/skills/windows-build/SKILL.md`.

## Version surfaces

| File | Covers |
|---|---|
| `macos-app/VERSION` | macOS app + bundled dialog CLI |
| `windows-app/VERSION` | Windows tray app + installer |
| `macos-app/Sources/Resources/base-prompt.md` (line 1) | Baseprompt, versioned independently |
| `docs/src/lib/data/releases.json` | Both platforms; drives the docs page and `CHANGELOG.md` |

These move independently. A baseprompt fix can ship without an app version bump, and vice versa.
