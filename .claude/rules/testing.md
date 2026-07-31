---
paths:
  - "test-cases/**"
  - "container/**"
  - "dialog-cli/Sources/**"
  - "macos-app/Sources/**"
---

# Where tests run

**Run the suites in the container.** `bun run test:container`, or a subset with
`SUITES="unit layout" bun run test:container`. Setup and knobs:
`container/README.md`.

Not a preference. `test:visual` and `test:keyboard` spawn a real dialog per
case — dozens of windows that take the screen and the keyboard for minutes. On
a machine somebody is using, that is disruptive *and* unreliable: anything that
steals focus mid-run corrupts the result silently. The visual suite spent
months photographing one stuck window and reporting OK.

The same goes for driving the CLI by hand to look at a change. A dialog on the
host interrupts whoever is at the keyboard. Use `container/launch.sh shell`.

| Suite | Where | Why |
|---|---|---|
| `bun test` | anywhere | no UI |
| `bun run test:layout` | anywhere, and in the container | renders off-display; nothing appears, nothing takes focus |
| `bun run test:visual` | **container** — but see below | spawns a dialog per fixture |
| `bun run test:keyboard` | **container** — but see below | spawns dialogs and types into them |
| `container/vnc-matrix.sh` | **container** | drives real keystrokes over VNC |

**One gap remains in the container**: no app can take key focus in the guest
session, so anything that types into a focused text field fails — 9 of 24
keyboard assertions. Arrows, Space, Escape, the hotkeys, the ⌘F chord, expiry
and all 78 screenshots work. Detail in `container/README.md`; do not "fix" it
by moving those tests back to the host, where they take the keyboard from
whoever is using it and corrupt on any focus change.

## What a green run does and does not mean

- The layout audit **waives** every state with a known open bug and prints the
  list, plus a `NOT VOUCHED FOR` line naming the issues. A pass covers the
  unwaived states only. Read the list before calling something releasable.
- The audit is structurally blind to SwiftUI `Text`: only the
  `NSViewRepresentable` widgets can be measured. A clipped label is caught by
  its consequences — an overlap, a box that stopped fitting — not directly.
  Text presence is OCR's job, in the visual suite.
- CI runs `bun test` and the layout audit. It cannot run the two that need a
  screen; those are only ever covered by a container run.

## Adding coverage

A fixture in `test-cases/cases/` reaches the debug menu and the screenshot
runner. It is **not** measured until it has a row in
`test-cases/skin-states/states.tsv`. Both halves or neither — see
`dialog-parity.md`.

States with no pane and no key script render in parallel; timing-sensitive ones
stay serial, because their settle delays were calibrated on an idle machine.
Do not "speed up" the audit by widening that split.
