$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$VersionFile = Join-Path $RepoRoot "windows-tray-app\VERSION"

# 1. Read version
if (-not (Test-Path $VersionFile)) {
    Write-Error "error: $VersionFile not found"
    exit 1
}
$Version = (Get-Content $VersionFile -Raw).Trim()
Write-Host "version: $Version"

# 2. Publish dialog-cli-windows
Write-Host ""
Write-Host "building dialog-cli-windows..."
$DialogCliDir = Join-Path $RepoRoot "dialog-cli-windows"
dotnet publish $DialogCliDir -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "ok: dialog-cli-windows built"

# 3. Publish windows-tray-app
Write-Host ""
Write-Host "building windows-tray-app..."
$TrayAppDir = Join-Path $RepoRoot "windows-tray-app"
dotnet publish $TrayAppDir -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "ok: windows-tray-app built"

# 4. Build MCP server
Write-Host ""
Write-Host "building mcp-server..."
$McpDir = Join-Path $RepoRoot "mcp-server"
Push-Location $McpDir
try {
    npx tsc
    if ($LASTEXITCODE -ne 0) { exit 1 }

    # Install production dependencies only
    npm install --omit=dev
    if ($LASTEXITCODE -ne 0) { exit 1 }
} finally {
    Pop-Location
}
Write-Host "ok: mcp-server built"

# 5. Verify build outputs exist
$TrayExe = Join-Path $RepoRoot "windows-tray-app\bin\Release\net8.0-windows\win-x64\publish\ConsultUserMCP.exe"
$DialogExe = Join-Path $RepoRoot "dialog-cli-windows\bin\Release\net8.0-windows\win-x64\publish\dialog-cli-windows.exe"
$McpDist = Join-Path $RepoRoot "mcp-server\dist"

if (-not (Test-Path $TrayExe)) { Write-Error "error: $TrayExe not found"; exit 1 }
if (-not (Test-Path $DialogExe)) { Write-Error "error: $DialogExe not found"; exit 1 }
if (-not (Test-Path $McpDist)) { Write-Error "error: $McpDist not found"; exit 1 }
Write-Host "ok: all build outputs verified"

# 6. Create dist directory
$DistDir = Join-Path $RepoRoot "dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

# 7. Run Inno Setup compiler
Write-Host ""
Write-Host "building installer..."
$IssFile = Join-Path $RepoRoot "scripts\windows-installer.iss"

# Find iscc.exe — check common locations
$IsccPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    (Get-Command iscc -ErrorAction SilentlyContinue)?.Source
) | Where-Object { $_ -and (Test-Path $_) }

if ($IsccPaths.Count -eq 0) {
    Write-Error "error: Inno Setup compiler (iscc.exe) not found. Install Inno Setup 6 from https://jrsoftware.org/isinfo.php"
    exit 1
}
$Iscc = $IsccPaths[0]
Write-Host "using: $Iscc"

& $Iscc $IssFile
if ($LASTEXITCODE -ne 0) { exit 1 }

# 8. Verify installer
$InstallerExe = Join-Path $DistDir "ConsultUserMCP-Setup-$Version.exe"
if (-not (Test-Path $InstallerExe)) {
    Write-Error "error: installer not found at $InstallerExe"
    exit 1
}
$Size = (Get-Item $InstallerExe).Length
if ($Size -lt 1000) {
    Write-Error "error: installer is suspiciously small ($Size bytes)"
    exit 1
}

Write-Host ""
Write-Host "ok: installer created at $InstallerExe ($([math]::Round($Size / 1MB, 1)) MB)"
