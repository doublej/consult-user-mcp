# Docs Site

## What this is

The SvelteKit site for the project — landing page, changelog, comparison, and a screenshot-generation harness. It also holds `releases.json`, which is the release source of truth for the whole repo, not just for this site.

## Mental model

**`src/lib/data/releases.json` is upstream of two things:** the `/changelog` route renders it, and `bun run changelog` generates the repo's `CHANGELOG.md` from it. Nothing else writes release history.

**The `/screenshots` routes are a rendering harness, not documentation.** They take type and platform params (`/screenshots/[type]/[platform]`, `/screenshots/dual/[left]/[right]`) and render dialog mockups for capture by `bun run screenshots`. They exist to produce marketing images, so changing their layout changes published assets.

Everything else under `routes/` is ordinary content.

## Important invariants

- **`CHANGELOG.md` is generated. Never hand-edit it.** Change `releases.json` and run `bun run changelog`.
- **`releases.json` records app changes only.** A docs-only change gets no entry.
- **Entries are user-facing benefits, not commit messages.** Full guidance with examples: `.claude/rules/release-notes.md`.
- Validate against `src/lib/data/releases.schema.json`.

## Common change patterns

**Adding a release** → an entry in `releases.json`, then `bun run changelog`. Usually part of the `release-app` skill rather than a standalone edit.

**Regenerating screenshots** → `bun run screenshots`. Check what changed before committing; these are published assets.

## Verification

```bash
cd docs && bun run dev       # local site
bun run changelog            # from repo root — regenerate and diff CHANGELOG.md
```

If the generated `CHANGELOG.md` diff contains anything you did not put in `releases.json`, something else edited it by hand.

## Related context

- `.claude/rules/release-notes.md` — how to phrase entries
- `.claude/skills/release-app/SKILL.md` — where `releases.json` fits in a release
- `src/lib/data/releases.schema.json`
