# Sketch CLI

## What this is

The grid layout editor behind the `propose_layout` MCP tool. A separate Swift CLI from the [[Dialog CLI]] — different binary, different command set, different problem. macOS only.

## Mental model

Not a dialog. It is an editor: the agent proposes a layout, the user rearranges blocks on a grid, and the result comes back as structured layout data.

Five commands (`Main.swift`):

| Command | Does |
|---|---|
| `templates` | Returns the built-in density templates |
| `describe` | Turns a layout into prose |
| `render` | Renders a layout without opening a window |
| `propose` | Opens the interactive editor — the one the MCP tool calls |
| `test` | Screenshot harness (`Testing/`) |

**Three renderers, one layout model.** `Rendering/` holds `AsciiRenderer`, `SvgRenderer`, and `DescriptionRenderer`. A change to `Models/LayoutModels.swift` or `SemanticLayout.swift` ripples into all three, and each one fails differently — ASCII misaligns, SVG produces valid-but-wrong output, description silently omits.

`Services/LayoutCompiler.swift` turns the editor state into the output model; `Services/ContentInference.swift` guesses block content from context.

## Important invariants

- **`propose_layout` is single-flight.** `mcp-server` guards against a second concurrent call, and the tool is removed entirely on Windows. Do not add a Windows path here.
- **This CLI ships in the app bundle too.** `mcp-server/src/providers/swift.ts` looks for it in the bundle first, then `.build/release/`. A debug-only build will not be found by the installed app.
- **Theme and window code are forked from the Dialog CLI, not shared.** `Theme/Theme.swift`, `Window/BorderlessWindow.swift`, and `Components/FocusableButton.swift` exist in both trees. A fix in one does not reach the other — port it deliberately or leave it.

## Common change patterns

**Changing the layout model** → update all three renderers and re-run the test harness. The ASCII output is the fastest way to see a model change go wrong.

**Adding a block type** → `Models/BlockStyles.swift`, `Views/BlockView.swift`, all three renderers, `AddBlockSheet.swift`.

## Verification

```bash
swift build                                  # from sketch-cli/
.build/debug/SketchCLI templates
.build/debug/SketchCLI test                  # screenshot harness → test-report/
```

`Testing/HtmlReportGenerator.swift` produces a browsable report — the practical way to review a rendering change.

## Related context

- `../mcp-server/CLAUDE.md` — how `propose_layout` reaches this binary
- `../test-cases/cases/sketch/` — fixtures
- `../dialog-cli/CLAUDE.md` — the sibling CLI these components were forked from
