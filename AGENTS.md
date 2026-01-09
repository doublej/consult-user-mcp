# AGENTS.md

## Build Commands
```bash
bun install && bun run build    # Full build (MCP server + Swift CLI)
bun run build:bundle            # Create macOS app bundle
cd mcp-server && bun run build  # TypeScript only
cd dialog-cli && swift build -c release  # Swift CLI only
```

## TypeScript (mcp-server/src/)
- **Target**: ES2022, NodeNext modules, strict mode
- **Imports**: External first, then local; use `type` for type-only imports
- **Types**: `interface` for objects, `type` for unions; Zod schemas for runtime validation
- **Naming**: camelCase (vars/funcs), PascalCase (types/interfaces)
- **Async**: Explicit `Promise<T>` return types; arrow functions for callbacks

## Swift (dialog-cli/, macos-app/)
- **Target**: Swift 5.9, macOS 14+
- **Types**: Structs + Codable for data models; classes for UI/managers
- **Imports**: Foundation first, then AppKit/SwiftUI
- **Naming**: camelCase (vars/funcs), PascalCase (types); `is` prefix for booleans
- **Errors**: `guard let` for early returns; `try?` for non-critical operations

## Notes
- No ESLint/Prettier/SwiftLint configured
- No test framework configured (manual testing via `mcp-server/test.js`)
