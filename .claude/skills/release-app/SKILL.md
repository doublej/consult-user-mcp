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
7. `bash scripts/release.sh --platform macos` — builds, packages, tags, creates the GitHub release.

`--dry-run` validates preconditions without executing. Use it first when anything about the state is uncertain.

### Two assets, both required

A macOS release ships a `.dmg` and a `.zip`, and neither is optional:

| Asset | Consumed by |
|---|---|
| `Consult.User.MCP.dmg` | a human downloading from the releases page — drag to `/Applications` |
| `Consult.User.MCP.app.zip` | `install.sh` and the in-app updater, both of which pick the first `.zip` asset |

`make-dmg.sh` builds and signs the dmg; dropping the zip breaks the auto-updater
for everyone already installed.

**The zip must contain no AppleDouble members.** `ditto -c -k` encodes any
extended attribute as a `._name` entry, and `update.sh` extracting that adds an
unsealed file to the bundle — the updated app then fails `codesign --verify` and
will not launch. `build-app.sh` runs `xattr -cr` before signing and `release.sh`
fails the release if any `._` entry survives. Both guards exist because one
xattr, set just by having run the app, shipped a bricked updater in 2.6.5.

`bash scripts/check-changelog-sources.sh` confirms the change list the update
prompt shows is actually fetchable. It needs at least one of the two sources in
`AppURLs.releasesJSONSources` — the Pages copy comes from the docs deploy, so it
lags a fresh release by a few minutes and the raw GitHub fallback covers the gap.

### Signing and notarization

`build-app.sh` signs the bundle whenever a **Developer ID Application** identity
is in the keychain, and skips silently when there is none — an unsigned build
still works locally. `release.sh` then notarizes and staples, but only if the
bundle actually came out Developer ID signed; otherwise it warns and ships
unsigned rather than failing.

Only the dmg is submitted. The ticket Apple issues covers the app nested inside
it, so both the dmg and the app staple from that one submission — and the zip is
made after stapling, so the zipped app carries the ticket too.

One-time machine setup:

```bash
# 1. Certificate — Xcode ▸ Settings ▸ Accounts ▸ <paid team> ▸ Manage Certificates
#    ▸ + ▸ Developer ID Application.  Verify:
security find-identity -v -p codesigning

# 2. Notarization credentials — app-specific password from appleid.apple.com
xcrun notarytool store-credentials consult-user-mcp \
  --apple-id <apple-id> --team-id <TEAM_ID> --password <app-specific-password>
```

Overrides: `CODESIGN_IDENTITY` picks a specific identity, `NOTARY_PROFILE`
a different stored profile.

Signing is deliberately part of `bun run dev` too — `dev-install.sh` swaps
binaries into the installed bundle, which invalidates the signature, and a
signed app with a broken seal will not launch at all. Dev builds sign without
a secure timestamp so they stay fast.

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
