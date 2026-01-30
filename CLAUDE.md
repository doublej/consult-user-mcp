# Claude Code Notes

## Development Workflow

The installed app at `/Applications/Consult User MCP.app` runs its own bundled binaries. Local builds do NOT automatically update the installed app.

**Use `bun run dev` for all development builds.** It builds everything (dialog-cli, mcp-server, macos-app) in debug mode and copies binaries into the installed app bundle. After running it, restart the tray app to pick up changes.

```bash
bun run dev          # Build all + install to /Applications (dev workflow)
bun run build        # Build mcp-server + dialog-cli only (no install)
bun run build:bundle # Full release build + create app bundle from scratch
```

**Important:** Never use bare `swift build` or `bun run build` during development — those only compile locally without updating the running app.

## tmux send-keys Submission Issue

When sending commands to tmux panes running Claude Code, use TWO separate commands:

```bash
# WRONG - Enter gets typed as literal text
tmux send-keys -t session:window.pane "command" Enter

# CORRECT - Separate send-keys for Enter
tmux send-keys -t session:window.pane "command"
tmux send-keys -t session:window.pane Enter

# ALSO CORRECT - Use C-m in same command
tmux send-keys -t session:window.pane "command" C-m
```

The issue is that when `Enter` follows a quoted string, it may be interpreted as part of the string or not processed correctly. Separating into two commands ensures reliable submission.

## Agent Coordination Pattern

When coordinating multiple Claude Code agents in tmux:

1. Send command text to pane
2. Wait briefly (0.1-0.3s)
3. Send Enter separately
4. Wait for agents to start processing before checking status

## Release Checklist

When releasing a new version:

1. Update `macos-app/VERSION` file with the new version number
2. **If baseprompt changed:** Update version in `macos-app/Sources/Resources/base-prompt.md` (first line comment)
3. Update `docs/src/lib/data/releases.json` (single source of truth)
4. Generate CHANGELOG.md: `bun run changelog`
5. Validate versions: `bash scripts/validate-baseprompt-version.sh`
6. Commit and tag: `git tag -a vX.Y.Z -m "vX.Y.Z - Description"`
7. Push with tags: `git push origin main --tags`
8. Build bundle: `bun run build:bundle`
9. Create zip: `cd /Applications && zip -r /tmp/Consult.User.MCP.app.zip "Consult User MCP.app" -x "*.DS_Store"`
10. Create GitHub release with zip: `gh release create vX.Y.Z /tmp/Consult.User.MCP.app.zip --title "..." --notes "..."`

## Baseprompt Versioning

The base prompt has its own independent version number:
- **Location:** `macos-app/Sources/Resources/base-prompt.md` (first line comment)
- **Format:** `<!-- version: X.Y.Z -->`
- **Current:** v1.3.1
- **Validation:** Run `bash scripts/validate-baseprompt-version.sh`
- **CI:** Automatically validated on every push/PR

**When to bump:**
- Major (X): Breaking changes to tool usage or workflow
- Minor (Y): New features, examples, or significant guidance improvements
- Patch (Z): Bug fixes, typos, clarifications

## Documentation Structure

- **`docs/src/lib/data/releases.json`** - Single source of truth for app releases
  - Feeds the /docs page: hero dialog (PerspectiveDialog) and changelist (Changelist)
  - Generates CHANGELOG.md via `bun run changelog`
  - Only include app changes, never docs-only changes
- **`CHANGELOG.md`** - Auto-generated from releases.json (do not edit manually)
- **`docs/src/lib/data/releases.schema.json`** - JSON schema for validation

### Writing Changelists

Write change entries as **user-facing features and benefits**, not commit messages:

| Bad (commit-style) | Good (user-facing) |
|---|---|
| Add markdown support | Text input dialogs now support markdown formatting |
| Fix snooze crash | Snooze feature now works reliably without crashes |
| Refactor DialogManager | Dialogs now focus correctly when switching apps |
| Add execute permission | Installation script now runs without permission errors |

Focus on what users can do or what's improved, not implementation details.
