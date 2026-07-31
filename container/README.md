# The container

A headless macOS VM that runs this project's tests, so they stop running on
your desktop.

Two of the suites spawn real dialogs. On your own machine they take the
screen and the keyboard for several minutes, and anything that steals focus
mid-run corrupts the result — which is how the visual suite came to spend
months photographing one stuck window and reporting OK. The container gives
them a machine of their own: a fixed OS build, a fixed display, fixed fonts,
and nothing else competing for focus.

## Use it

```bash
container/launch.sh check          # preflight: tart, disk, VM, guest
container/launch.sh run            # the full suite; artifacts in container/out/
VIEWER=1 container/launch.sh run   # same, but watch it on its own full-screen Space
```

or `bun run test:container`.

First time on a machine:

```bash
container/launch.sh init    # clone the base image
container/launch.sh prep    # toolchain, agents, screen-recording grant
```

`prep` is idempotent and only needs re-running when `prep.sh` itself
changes — not when the suite changes. See "Why the guest can't go stale".

## What a run does

Inside the guest, against a fresh copy of your working tree:

| Suite | What it proves |
|---|---|
| `unit` | the MCP server's own tests |
| `layout` | every state measured — clipping, overlap, text that does not fit |
| `keyboard` | the typing-vs-hotkey contract, arrows, Space, the Escape ladder |
| `visual` | a screenshot per fixture, OCR'd against the words that should be on it |

Pick a subset with `SUITES="unit layout"`. Artifacts come back in
`container/out/`: `run.log` with the summary, a full `<suite>.log` per suite,
`screenshots/`, `audit/`, and `done` carrying the verdict.

## Known limitation: no app can take key focus here

One class of test still cannot pass in the VM: anything that types into a
focused text field. The guest's session will not let an application become
active — verified with a minimal AppKit app, not just this one — so no window
becomes key, nothing takes first responder, and the key router reads every
letter as the shortcut it is when you are not editing. Typing
`safari for fast assets` into a field comes back as `answer: "fri "` with
`feedbackText: "or fast assets"`, identically at 0ms, 20ms and 40ms between
keystrokes, so it is not a timing problem.

That is 9 of 24 keyboard assertions. Everything else works: arrows, Space,
Escape, the hotkeys, the ⌘F chord, expiry, and all 78 screenshots.

Worth knowing what this used to look like. Until the audit, dialogs did not
appear in the VM **at all** — the chime was played synchronously on the main
thread just before the window was built, and the guest's audio device never
answers, so the process sat in the audio HAL forever. The visual suite hid it
by photographing one leftover window 78 times and reporting OK. Fixing the
sound took captures from 7/78 to 77/78 and keyboard assertions from 0 to 15.

## Commands

| | |
|---|---|
| `check` | preflight only — safe to run any time |
| `init` | clone the base image into `tahoe-consult` and size it |
| `prep` | provision the guest |
| `run` | sync the repo in, run the suites, copy artifacts out |
| `shell` | boot with a viewer, for looking at something by hand |
| `stop` | shut it down |
| `clean` | delete the clone; the base image is left alone |

## Knobs

| Env | Default |
|---|---|
| `SUITES` | `unit layout keyboard visual` |
| `CUM_VM_NAME` | `tahoe-consult` |
| `CUM_REPO` | the repo this file is in |
| `CUM_CPU` / `CUM_MEM` | `6` / `12288` MiB |
| `CUM_DISPLAY` | `1512x982` — changes which dialogs clamp; see Gotchas |
| `DIALOG_SKIN` / `SKINS` | `caret` |
| `VIEWER=1` | boot with a window and put it full screen on its own Space, to watch |
| `REUSE=1` | reuse a running VM instead of rebooting it |
| `TIMEOUT` | `1800` seconds |

## Why the guest can't go stale

`prep` bakes exactly one thing into the VM: a five-line shim that rsyncs the
repo and hands over to `container/guest-run.sh`. Everything else lives in
this directory, in the repo, and arrives with the code it tests.

That is not tidiness. The old arrangement wrote the whole runner into the VM
at prep time, so the guest kept executing whatever the harness looked like
the last time somebody remembered to re-prep — and the symptom was output
missing lines the current script obviously printed.

The other half of the same problem is VirtioFS: a VM that has been up a
while serves stale bytes for files the host has since changed. So `run`
reboots by default (`REUSE=1` opts out), and both sides compute a
fingerprint over the sources. If they disagree the run stops and says so,
rather than testing yesterday's code and calling it today's.

## Gotchas

- **`--vnc-experimental`, never `--no-graphics`.** Without an attached
  framebuffer the WindowServer never maps a window: `makeKeyAndOrderFront`
  quietly does nothing and every capture comes back empty. The experimental
  VNC path attaches a real virtual framebuffer and opens no viewer on the
  host, which is what makes a run invisible rather than absent.
- **The work happens in a LaunchAgent, not over `tart exec`.** `tart exec`
  lands in `user/501`, which has no GUI. A `gui/501` LaunchAgent watches a
  trigger file; the host touches it. Settings travel through
  `out/request.env` because a LaunchAgent inherits no environment.
- **Screen Recording is pre-granted** by writing TCC.db directly (SIP is off
  in the cirruslabs base images). Without it `screencapture -l <wid>` fails
  with "could not create image from window" while the window is plainly on
  screen — which reads as a layout bug rather than a permissions one.
- **`TART_HOME` is on an external disk.** `check` mounts it if it has been
  ejected. An unmounted `TART_HOME` does not error; `tart` just reports no
  VMs, which looks like the VM was deleted.
- **The display is part of the test, not a setting.** The dialog height cap is
  derived from the screen, so screen size decides which states clamp. tart's
  default is 768pt tall — shorter than any machine a customer owns — and on it
  the container reported six states overflowing that are fine on a real
  display. It is pinned to `1512x982`, the 13" MacBook Air's logical size:
  a fair floor that is still real. Override with `CUM_DISPLAY`, and expect the
  verdict to move when you do.

## Files

| | |
|---|---|
| `launch.sh` | the host driver — everything above |
| `prep.sh` | guest provisioning; the only thing baked into the VM |
| `guest-run.sh` | what the guest actually runs, from the repo |
| `vnc-matrix.sh` | end-to-end scenarios driven over VNC with real keystrokes |
| `out/` | artifacts (gitignored) |
