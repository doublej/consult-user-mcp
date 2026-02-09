# Building for Windows

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Node.js](https://nodejs.org/) (18+)
- [Velopack CLI](https://docs.velopack.io/) (`dotnet tool install -g vpk`)

## Development

Build both projects for local testing:

```bash
# Dialog CLI
cd dialog-cli-windows && dotnet build

# Tray app
cd windows-app && dotnet build
```

Or use the package.json scripts:

```bash
bun run build:cli:windows   # Build dialog-cli
bun run dev:windows-app     # Build tray app (debug)
bun run build:windows-app   # Build tray app (release)
```

## Building the Installer

Run from the repository root on a Windows machine:

```powershell
pwsh scripts/build-windows-installer.ps1
```

This will:

1. Build `dialog-cli.exe` (self-contained, win-x64)
2. Build `consult-user-mcp.exe` (self-contained, win-x64)
3. Build the MCP server (`npm ci && npm run build`)
4. Assemble everything into a staging directory
5. Run `vpk pack` to create the Velopack installer

Output is written to `releases/windows/`.

### Custom version

```powershell
pwsh scripts/build-windows-installer.ps1 -Version 1.2.0
```

## Creating a Release

After building the installer on Windows:

1. Copy the `releases/windows/` directory to the macOS machine (or make it accessible)
2. Run: `bash scripts/release.sh --platform windows --asset-dir releases/windows`

Use `--dry-run` to validate pre-conditions first.

## Installation Structure

After installing, the app is located at:

```
C:\Users\<user>\AppData\Local\ConsultUserMCP\
├── current\
│   ├── consult-user-mcp.exe    # Tray app (main executable)
│   ├── dialog-cli.exe           # CLI spawned by MCP server
│   └── mcp-server\             # Node.js MCP server
│       ├── dist\index.js
│       └── node_modules\
└── Update.exe                   # Velopack updater
```

User data is stored at `%APPDATA%\ConsultUserMCP\` (settings, snooze state, history).
