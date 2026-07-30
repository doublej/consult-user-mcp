# Consult User MCP Glossary

The vocabulary of this project. One concept → one canonical term. Use these words in code, commits, docs, issue titles, and agent prompts.

Wire names are exempt. The MCP tool surface, the CLI commands, and the JSON response fields are public contracts — they keep the names they have. Where a concept has a different name at each layer, see [Layer Translation](#layer-translation) rather than renaming anything.

## Core Concepts

### Dialog
A window that asks the user something and blocks the calling agent until it is answered, cancelled, or snoozed.
- **Rejected synonyms:** popup, prompt, modal, alert
- **Related:** [[Pane]], [[Response]], [[Skin]]

### Pane
A window that appears without asking anything and closes itself after a few seconds. Only `notify` and `preview` produce panes.
- **Rejected synonyms:** toast, banner, notification window
- **Related:** [[Dialog]]

### Feedback
Free-text the user leaves *alongside* their answer, not instead of it. Arrives as `feedbackText`, or `feedbackByQuestion` on a [[Form]].
- **Rejected synonyms:** comment, remark, message
- **Permitted UI copy:** "note" — user-facing strings say "Note on this dialog"; identifiers and docs say feedback
- **Related:** [[Feedback Pane]]

### Feedback Pane
The editor that slides in beside a [[Dialog]] to type [[Feedback]] into. A sub-surface of a dialog, not a [[Pane]] in its own right.
- **Rejected synonyms:** feedback drawer, comment box, sidebar

### Form
The multi-question [[Dialog]]. Presented as a [[Wizard]].
- **Rejected synonyms:** survey, questionnaire, multi-question dialog
- **Related:** [[Wizard]], [[Question]]

### Wizard
The one-question-at-a-time presentation of a [[Form]]. A presentation style, not a separate dialog type — there is no "wizard dialog" distinct from a form.
- **Rejected synonyms:** stepper, carousel

### Question
One item inside a [[Form]]: an id, a prompt, and either options or a text field.
- **Related:** [[Form]]

### Snooze
A global quiet period the user sets from any [[Dialog]]. While active, every dialog call returns immediately with `remainingSeconds` and nothing is shown.
- **Rejected synonyms:** mute, pause, defer, quiet mode
- **Related:** [[Response]]

### Ask Differently
The user rejecting the *shape* of the question rather than answering it, asking for the same question re-posed as another dialog type.
- **Rejected synonyms:** retry, rephrase, change type, reformat

### Skin
A complete visual implementation of the dialog set — layout, spacing, composition. Selected with `DIALOG_SKIN`. `classic` and `alt` ship today.
- **Rejected synonyms:** variant, shell, frontend, style
- **Related:** [[Theme]]

### Theme
The colour and radius token set a [[Skin]] renders with. Selected with `DIALOG_THEME`. A skin may declare a preferred theme; an explicit `DIALOG_THEME` still wins.
- **Rejected synonyms:** palette, colour scheme, appearance
- **Related:** [[Skin]]

### Baseprompt
The versioned instruction document the MCP server hands to the client via the protocol's `instructions` field. Never inlined into a `CLAUDE.md`.
- **Rejected synonyms:** system prompt, base prompt (two words, in identifiers), instructions blob
- **Source of truth:** `macos-app/Sources/Resources/base-prompt.md`

### Provider
The platform implementation behind the MCP tool surface. One per operating system; selected at runtime by `createProvider()`.
- **Rejected synonyms:** backend, adapter, driver, platform layer

### Dialog CLI
The ephemeral binary spawned once per [[Dialog]], which prints a [[Response]] and exits.
- **Rejected synonyms:** dialog binary, helper binary, the Swift CLI

### Tray App
The persistent background app that owns settings, history, updates, and the debug menu.
- **Rejected synonyms:** menu bar app, macOS app, status item app, the desktop app

### Tweak Parameter
One numeric value bound to a location in a file, adjustable by a slider, written back live.
- **Rejected synonyms:** slider, control, knob, variable

### Cooldown
The brief interval after a [[Dialog]] appears during which buttons and keys are inert, so a keystroke meant for the editor cannot accidentally answer it.
- **Rejected synonyms:** debounce, grace period, lockout

### Expired
The state a [[Dialog]] enters when the MCP server's timeout elapses before the user answers: the agent has already continued with its best guess, the window stays on screen behind an overlay saying so, and every control is inert until the user closes it. Armed via the `MCP_DIALOG_TIMEOUT_MS` env var; owned by `DialogExpiry`.
- **Rejected synonyms:** timed out, abandoned, stale, orphaned

### Test Case
A JSON fixture under `test-cases/cases/<type>/`. Feeds both the visual test runner and the tray app's debug menu.
- **Rejected synonyms:** fixture, sample, scenario, test file

### Position
Where on screen a [[Dialog]] appears: `left`, `center`, or `right`.
- **Rejected synonyms:** placement, anchor, alignment, location

### Sketch
The grid layout editor behind the `propose_layout` tool. Its own CLI, not part of the [[Dialog CLI]].
- **Rejected synonyms:** layout editor, wireframe tool, canvas

### Response
The compacted JSON a [[Dialog CLI]] prints on stdout. `answer` is a *field* of a response, not a synonym for it.
- **Rejected synonyms:** result, output, return value

## Layer Translation

The same dialog is named differently at each layer. All three names are correct **in their own layer** — do not "fix" them. Use this table when tracing a dialog end to end.

| Concept | MCP (`ask` type) | CLI command | Swift type | C# type | Test case dir |
|---|---|---|---|---|---|
| Yes/no | `confirm` | `confirm` | `SwiftUIConfirmDialog` | `ConfirmDialog` | `confirm/` |
| Single-select | `pick` | `choose` | `SwiftUIChooseDialog` | `ChooseDialog` | `choose/` |
| Multi-select | `pick` + `multi` | `choose` + `multi` | `SwiftUIChooseDialog` | `ChooseDialog` | `choose/` |
| Text entry | `text` | `textInput` | `SwiftUITextInputDialog` | `TextInputDialog` | `text-input/` |
| Password entry | `text` + `hidden` | `textInput` + `hidden` | `SwiftUITextInputDialog` | `TextInputDialog` | `text-input/` |
| [[Form]] | `form` | `questions` | `SwiftUIWizardDialog` | `WizardDialog` | `questions/` |
| Notification | (`notify` tool) | `notify` | `SwiftUINotifyPane` | `NotifyWindow` | `notify/` |
| Value adjustment | (`tweak` tool) | `tweak` | `SwiftUITweakDialog` | — *(unsupported)* | `tweak/` |
| Layout editor | (`propose_layout` tool) | `sketch-cli` | `SketchEditorView` | — *(unsupported)* | `sketch/` |

Internally the dialog-type string for a [[Form]] is `"form-wizard"` — that is the [[Form]] concept plus its [[Wizard]] presentation, not a third type.

## Process Vocabulary

- **Dev install** — `bun run dev`. Builds debug binaries and copies them into the installed app bundle. The only build that changes what the installed app runs.
- **Bundle build** — `bun run build:bundle`. Builds a release app bundle from scratch.
- **Baseprompt bump** — editing `base-prompt.md` *and* its version comment together. One without the other fails validation.
- **Visual test run** — `bun run test:visual`. Screenshots every [[Test Case]].
- **Release** — version files, `releases.json`, generated changelog, tag, GitHub release with assets attached.

## Known Inconsistencies

Recorded rather than silently renamed. Fix each at its next natural touch point.

- The [[Baseprompt]] calls `tweak` an "always-on-top slider **pane**". By this glossary it is a [[Dialog]] — it is modal and returns an answer. Correct at the next baseprompt version bump, since editing that file requires a version bump and validation.
- `comment` survives as an always-null field in every dialog [[Response]] model. It is stripped by `compact.ts` and never populated. Delete when the response models are next touched.
- UI copy says "Note" where the domain term is [[Feedback]] (`FeedbackPane.swift`, the per-question tooltip). Permitted as user-facing copy; do not propagate into identifiers.

## Out of Scope

Terms deliberately not used by this project:

- **Toast / snackbar** — web vocabulary. Use [[Pane]].
- **Modal** — every [[Dialog]] is modal, so the word carries no information here.
- **Widget** — too vague. Name the actual component.
- **Manager** as a domain word — it is a stack suffix (`DialogManager`, `SnoozeManager`), never a concept.
