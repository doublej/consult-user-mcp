---
paths:
  - "dialog-cli/Sources/**"
  - "dialog-cli-windows/**"
  - "mcp-server/src/**"
  - "test-cases/**"
---

# Dialog parity

Adding or changing a dialog type touches more places than it looks. A change that lands in only one of them ships a dialog that works on one platform, or one the debug menu cannot open, or one the test runner silently skips.

When you add a dialog type, or change the request/response shape of an existing one, walk this list:

| Where | What changes |
|---|---|
| `mcp-server/src/index.ts` | Zod schema, tool registration |
| `mcp-server/src/types.ts` | Option and result interfaces |
| `mcp-server/src/providers/interface.ts` | Method on `DialogProvider` |
| `mcp-server/src/providers/swift.ts` | macOS implementation |
| `mcp-server/src/providers/windows.ts` | Windows implementation, or an explicit throw |
| `mcp-server/src/compact.ts` | Response compaction |
| `dialog-cli/Sources/DialogCLI/Main.swift` | Command switch |
| `dialog-cli/Sources/DialogCLI/Models/` | Request + response models |
| `dialog-cli/Sources/DialogCLI/Skins/DialogSkin.swift` | `DialogKind` case, spec struct, protocol method |
| `dialog-cli/Sources/DialogCLI/Skins/Classic/ClassicSkin.swift` | Implementation + window metrics |
| `dialog-cli-windows/Services/DialogManager.*.cs` | Windows equivalent |
| `test-cases/cases/<type>/` | At least one fixture |
| `test-cases/test-runner.sh` | Directory → CLI command mapping (~line 88) |
| `macos-app/Sources/AppDelegate.swift` | Debug menu entry, loading from `test-cases/cases/` |

Two hard rules:

- **The debug menu loads dialog JSON from `test-cases/cases/`.** Never hardcode dialog JSON in `AppDelegate.swift`.
- **`tweak` and `propose_layout` are macOS-only.** `WindowsDialogProvider` throws for both. Keep the throw explicit rather than letting it fail somewhere further down.

Every response shape must survive `compact.ts`: null fields stripped, `confirmed` mapped to `answer`, `dismissed` merged into `cancelled`. Compact priority is snoozed > askDifferently > feedbackText > cancelled > answer.
