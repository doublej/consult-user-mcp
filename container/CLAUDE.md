# Container

## What this is

A headless macOS VM (tart) that the test suites run inside. `README.md` is
the operating manual; this file is what to know before editing anything here.

**Run the suites here, not on the host.** `test:keyboard` and `test:visual`
spawn real dialogs — on a desktop somebody is using they take the screen and
the keyboard for minutes, and any focus change corrupts the result.
`test:layout` renders off-screen and is safe anywhere, but the container is
still where a verdict should come from, because there the display, the OS
build and the font set are fixed.

## Mental model

```
launch.sh        host driver. preflight, boot, trigger, collect.
prep.sh          guest provisioning. The ONLY thing baked into the VM.
  └─ invoke.sh   five-line shim it writes: rsync, then exec the repo's guest-run.sh
guest-run.sh     the actual pass. Lives here, arrives with the code it tests.
vnc-matrix.sh    end-to-end scenarios over VNC, real keystrokes, jq assertions.
out/             artifacts back from the guest (gitignored)
```

Host and guest never share a process. They talk through two folders: `repo`
(read-only, the working tree) and `out` (read-write, artifacts *and* the
control channel — `request.env` in, `run.log` and `done` back).

## Important invariants

- **Nothing that can change may be baked into the VM.** `prep.sh` writes
  `invoke.sh` and stops. If you add a step to the pass, it goes in
  `guest-run.sh`, which is rsynced fresh every run. The moment the guest
  carries its own copy of the suite, it starts running a different one from
  the sources under it — that failure is silent and costs hours.
- **`--vnc-experimental`, never `--no-graphics`.** No framebuffer means the
  WindowServer maps no windows, `makeKeyAndOrderFront` no-ops, and captures
  come back empty rather than wrong.
- **The pass runs in `gui/501`, not over `tart exec`.** `tart exec` has no
  GUI session. Hence the WatchPaths LaunchAgent, and hence settings arriving
  by file — launchd hands a job no environment.
- **A run reboots the VM by default.** VirtioFS on a long-lived VM serves
  stale file content, so the guest can rsync bytes the host replaced minutes
  ago. `REUSE=1` skips the reboot when you know the tree has not moved.
- **Both sides fingerprint the sources.** A mismatch aborts the run. It is
  the only thing standing between a stale share and a test result nobody can
  reproduce.
- **Screen Recording is granted by writing TCC.db.** Only possible because
  SIP is off in the cirruslabs base images. If a capture ever fails with
  "could not create image from window", check the grant before the layout.

## Common change patterns

**Adding a suite** → a block in `guest-run.sh` guarded by `$SUITES`, and a
line in the README table. No re-prep.

**Adding a guest dependency** → `prep.sh`, then `launch.sh prep` once.

**Debugging a state by hand** → `launch.sh stop && launch.sh shell` boots
with a viewer. The repo is mounted read-only at
`/Volumes/My Shared Files/repo`; the guest works in `~/work/consult-user-mcp`.

**A run that hangs** → `out/run.log` is written live; `tart exec
tahoe-consult bash -lc 'tail ~/.consult-mcp-runner/agent.log'` reaches the
agent's own log when the shared folder is the thing that broke.

## Related context

- `../test-cases/CLAUDE.md` — the suites themselves, and what they can see
- `../CLAUDE.md` — where the container sits in the project
- `README.md` — the operating manual
