---
paths:
  - "macos-app/Sources/Resources/base-prompt.md"
  - "windows-app/Resources/**"
  - "mcp-server/src/index.ts"
---

# Baseprompt changes

The baseprompt is the instruction document every MCP client receives on connect. It is versioned independently of the apps.

**Editing the content and bumping the version are one change, not two.** `scripts/validate-baseprompt-version.sh` gates this.

- **Source of truth:** `macos-app/Sources/Resources/base-prompt.md`. Line 1 is `<!-- version: X.Y.Z -->`.
- **Delivery:** `mcp-server/src/index.ts:loadBasePrompt()` reads the bundled copy and returns it in the protocol's `instructions` field. It is never inlined into any `CLAUDE.md`.
- **Bundled copy:** `/Applications/Consult User MCP.app/Contents/Resources/base-prompt.md`, refreshed by `bun run dev`. Editing the source alone does not change what a running client sees.
- **Global pointer:** `~/.claude/CLAUDE.md` records only the path as an HTML comment. An `@`-import there would expand the file inline and double the prompt — the validator checks for this.

Version bump semantics: major for breaking tool or workflow changes, minor for new features and guidance, patch for fixes and typos.

Budget matters. Clients truncate — keep the critical contract inside the first ~2.5KB and let tool schemas carry per-field documentation.
