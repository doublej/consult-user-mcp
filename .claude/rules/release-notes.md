---
paths:
  - "docs/src/lib/data/releases.json"
  - "CHANGELOG.md"
---

# Release notes

`docs/src/lib/data/releases.json` is the single source of truth for app releases. It feeds the docs page and generates `CHANGELOG.md` via `bun run changelog`.

- **`CHANGELOG.md` is generated. Never edit it by hand.** Change `releases.json` and regenerate.
- **App changes only.** Docs-only changes do not get a release entry.
- Validate against `docs/src/lib/data/releases.schema.json`.

Write what the user gets, not what the commit did:

| Don't | Do |
|---|---|
| Add markdown support | Text input dialogs now support markdown formatting |
| Fix snooze crash | Snooze now works reliably without crashing |
| Refactor DialogManager | Dialogs now focus correctly when switching apps |
| Add execute permission | The installation script now runs without permission errors |

A reader of the changelog has not read the diff and does not know the class names. If an entry only makes sense to someone who has, rewrite it.
