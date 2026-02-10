$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$VersionFile = Join-Path $RepoRoot "windows-app\VERSION"

# 1. Read version
if (-not (Test-Path $VersionFile)) {
    Write-Error "error: $VersionFile not found"
    exit 1
}
$Version = (Get-Content $VersionFile -Raw).Trim()
Write-Host "version: $Version"

# 2. Publish dialog-cli
Write-Host ""
Write-Host "building dialog-cli..."
$DialogCliDir = Join-Path $RepoRoot "dialog-cli-windows"
dotnet publish $DialogCliDir -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "ok: dialog-cli built"

# 3. Publish windows-app (no PublishSingleFile — Velopack manages packaging)
Write-Host ""
Write-Host "building windows-app..."
$TrayAppDir = Join-Path $RepoRoot "windows-app"
dotnet publish $TrayAppDir -c Release -r win-x64 --self-contained
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "ok: windows-app built"

# 4. Build MCP server
Write-Host ""
Write-Host "building mcp-server..."
$McpDir = Join-Path $RepoRoot "mcp-server"
Push-Location $McpDir
try {
    npx tsc
    if ($LASTEXITCODE -ne 0) { exit 1 }

    npm install --omit=dev
    if ($LASTEXITCODE -ne 0) { exit 1 }
} finally {
    Pop-Location
}
Write-Host "ok: mcp-server built"

# 5. Stage all files
Write-Host ""
Write-Host "staging files..."
$StagingDir = Join-Path $RepoRoot "dist\staging"
if (Test-Path $StagingDir) {
    Remove-Item -Recurse -Force $StagingDir
}
New-Item -ItemType Directory -Path $StagingDir | Out-Null

# Copy tray app publish output (directory of files)
$TrayPublishDir = Join-Path $RepoRoot "windows-app\bin\Release\net8.0-windows\win-x64\publish"
Copy-Item -Path "$TrayPublishDir\*" -Destination $StagingDir -Recurse

# Copy dialog-cli.exe
$DialogExe = Join-Path $RepoRoot "dialog-cli-windows\bin\Release\net8.0-windows\win-x64\publish\dialog-cli.exe"
Copy-Item -Path $DialogExe -Destination $StagingDir

# Copy mcp-server (install deps fresh — workspaces hoist to root, so mcp-server/node_modules doesn't exist)
$McpStagingDir = Join-Path $StagingDir "mcp-server"
New-Item -ItemType Directory -Path $McpStagingDir | Out-Null
Copy-Item -Path (Join-Path $McpDir "dist") -Destination (Join-Path $McpStagingDir "dist") -Recurse
Copy-Item -Path (Join-Path $McpDir "package.json") -Destination $McpStagingDir
Push-Location $McpStagingDir
try {
    npm install --omit=dev 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Error "error: npm install in staging failed"; exit 1 }
} finally {
    Pop-Location
}

Write-Host "ok: files staged"

# 6. Verify staged outputs
$StagedTrayExe = Join-Path $StagingDir "consult-user-mcp.exe"
$StagedDialogExe = Join-Path $StagingDir "dialog-cli.exe"
$StagedMcpDist = Join-Path $StagingDir "mcp-server\dist"

if (-not (Test-Path $StagedTrayExe)) { Write-Error "error: $StagedTrayExe not found"; exit 1 }
if (-not (Test-Path $StagedDialogExe)) { Write-Error "error: $StagedDialogExe not found"; exit 1 }
if (-not (Test-Path $StagedMcpDist)) { Write-Error "error: $StagedMcpDist not found"; exit 1 }
Write-Host "ok: all staged outputs verified"

# 7. Run Velopack pack
Write-Host ""
Write-Host "packing with Velopack..."
$OutputDir = Join-Path $RepoRoot "releases\windows"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

vpk pack --packId ConsultUserMCP --packVersion $Version --packDir $StagingDir --mainExe consult-user-mcp.exe --outputDir $OutputDir
if ($LASTEXITCODE -ne 0) {
    Write-Error "error: vpk pack failed"
    exit 1
}

# 8. Verify output
$SetupExe = Get-ChildItem -Path $OutputDir -Filter "*.exe" | Select-Object -First 1
if (-not $SetupExe) {
    Write-Error "error: no installer found in $OutputDir"
    exit 1
}
$Size = $SetupExe.Length
if ($Size -lt 1000) {
    Write-Error "error: installer is suspiciously small ($Size bytes)"
    exit 1
}

Write-Host ""
Write-Host "ok: installer created at $($SetupExe.FullName) ($([math]::Round($Size / 1MB, 1)) MB)"
