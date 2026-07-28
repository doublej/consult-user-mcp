# Dialog Skins

A **skin** is a complete visual implementation of the dialog set. Two ship today:

| id | Where | What it is |
|----|-------|-----------|
| `classic` | `Skins/Classic/` | The shipping UI. Wraps the existing `Dialogs/SwiftUI*Dialog` views — pure indirection, no visual change. |
| `alt` | `Skins/Alt/` | Scaffold for a second, independent UI. Own layout, own tokens. |

## The switch

Precedence: `DIALOG_SKIN` env var → `"skin"` in `settings.json` → `classic`.

```bash
DIALOG_SKIN=alt dialog-cli confirm '{"body":"Ship it?","title":"Deploy"}'
```

```jsonc
// ~/Library/Application Support/ConsultUserMCP/settings.json
{ "skin": "alt" }
```

An unknown id warns on stderr and falls back to `classic`; stdout stays valid JSON.

## What a skin owns

Layout and appearance. Nothing else.

`DialogManager` keeps the modal lifecycle, response building, history and snooze
checks. It hands the skin a **spec** — request data plus prebuilt callbacks — and
asks for a view:

```swift
let spec = ConfirmSpec(title: …, body: …, onConfirm: …, onCancel: …, …)
let (window, _, _) = createSkinnedWindow(.confirm, position: position) { skin in
    skin.confirmView(spec)
}
```

The skin also supplies `metrics(for:)`, so it can size its own windows without
touching `DialogManager`.

## Adding a skin

1. Add a type conforming to `DialogSkin` under `Skins/<Name>/`.
2. Implement only the dialogs you have reskinned — every `DialogSkin` member has
   a default that falls through to `ClassicSkin`, so a half-finished skin runs.
3. Add one line to `SkinRegistry.entries`. That is the whole wiring.
4. Optional: return a `preferredTheme`. It is applied on activation and restyles
   the shared AppKit widgets. An explicit `DIALOG_THEME` still wins, because
   `Main.run()` reads it after skin resolution.

## Shared chassis

Skins are expected to reuse the behavioural layer so keyboard routing, snooze,
feedback and the report overlay stay identical everywhere:

- `DialogContainer` — key router, feedback pane, snooze panel, report overlay,
  project badge. Wrap your content in it.
- `FocusableButton` / `FocusableTextField` / `FocusableChoiceCard` — AppKit views
  registered with `FocusManager`; arrow/Tab navigation only works through these.
- `DialogToolbar`, `KeyboardHintsView`, `AutoSizingScrollView`, `MarkdownParser`.

All of them read the global `Theme`, so a skin's `preferredTheme` restyles them
for free.

## Known gaps in `alt`

- `tweakView` is not implemented — it falls through to the Classic tweak pane.
- Choice rows reuse `FocusableChoiceCard` and `OtherChoiceCard` from
  `Dialogs/ChooseDialog.swift`. Fork them into `Skins/Alt/` if Alt needs a
  different card, keeping the `FocusManager.registerContent` call.

## Sizing caveat

Window width comes from `NSHostingView.fittingSize`, so any pane a skin adds
needs a deterministic width. `AltActionBar` measures its button labels for this
reason — a flexible right-aligned `HStack` would make the window width vary run
to run.
