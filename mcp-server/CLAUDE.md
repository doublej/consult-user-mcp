# MCP Server

## What this is

The MCP server itself: the tool surface an agent sees, and the routing that turns a tool call into a spawned [[Dialog CLI]] process. TypeScript, built and tested with Bun.

## Mental model

**Four tools, one provider.** `ask`, `notify`, `tweak`, `propose_layout` are registered in `index.ts`. Each defines a Zod schema, registers via `server.registerTool()`, and delegates to a method on `DialogProvider`.

`ask` is a router, not a dialog — its `type` field selects the method:

| `ask` type | Provider method |
|---|---|
| `confirm` | `provider.confirm()` |
| `pick` | `provider.choose()` |
| `text` | `provider.textInput()` |
| `form` | `provider.questions()` |

**Platform lives behind the interface.** `createProvider()` returns `WindowsDialogProvider` on `win32`, `SwiftDialogProvider` otherwise. Everything platform-specific is inside `providers/`; nothing above that layer branches on OS.

**Responses are compacted before they reach the agent.** `compact.ts` strips null fields, maps `confirmed` → `answer`, merges `dismissed` into `cancelled`. Priority when several states could apply: snoozed > askDifferently > feedbackText > cancelled > answer.

**The `tweak` resolvers turn a description into a file location.** `css-resolver.ts` handles selector + property; `text-search-resolver.ts` handles a `{v}` search pattern; `resolve-utils.ts` is shared. This is why `tweak` can be called without line numbers.

## Important invariants

- **`tweak` and `propose_layout` are macOS-only.** `WindowsDialogProvider` throws for both, and `propose_layout` is removed from the tool list entirely on `win32`. Keep the throw explicit.
- **The [[Baseprompt]] ships through the protocol, not through a file.** `loadBasePrompt()` reads the bundled `base-prompt.md` and returns it in the `instructions` field. It is never inlined into a `CLAUDE.md`. See `.claude/rules/baseprompt.md`.
- **`propose_layout` is single-flight.** A module-level `proposeLayoutActive` guard rejects a second concurrent call.
- **Every response shape must survive `compact.ts`.** A new field that should reach the agent has to be handled there or it is silently dropped.
- **Attachments bypass compaction on purpose.** `takeAttachments()` strips the image list off the raw response *before* `compactResponse`, and `attachmentBlocks()` turns it into MCP image content blocks. The base64 must never reach `structuredContent`, which is echoed into the transcript as JSON. macOS only for now — the Windows CLI emits no `attachments`, and the absent key degrades to no images rather than an error.
- **Choices are validated.** `validate-choices.ts` rejects meta-options like "all of the above" — the dialog is for real choices.

## Common change patterns

**Adding a tool** → Zod schema + `registerTool` in `index.ts`, types in `types.ts`, method on `providers/interface.ts`, both provider implementations, compaction in `compact.ts`, tests.

**Adding a platform** → implement `DialogProvider` in `providers/<os>.ts` and add a branch to `createProvider()`. Every method must return a well-formed cancel result rather than throwing when the user dismisses.

**Changing a response shape** → `compact.ts` and its tests, then both CLIs. Full list: `.claude/rules/dialog-parity.md`.

## Verification

```bash
bun test          # 144 tests, mostly compaction and validation
bun run build     # compile
bun run dev       # watch mode
```

`compact.ts` is the highest-value thing to test — it is where response bugs become invisible.

## Related context

- `../GLOSSARY.md` — Layer Translation table: MCP name ↔ CLI command ↔ platform type
- `../dialog-cli/CLAUDE.md`, `../dialog-cli-windows/CLAUDE.md` — what the providers spawn
- `.claude/rules/dialog-parity.md`
- `docs/` — the rewind-checkpoint limitation and other product-level caveats belong there, not here
