$ErrorActionPreference = "Stop"

$DryRun = $false
if ($args -contains "--dry-run") {
    $DryRun = $true
    Write-Host "=== DRY RUN ==="
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$VersionFile = Join-Path $RepoRoot "windows-app\VERSION"

# 1. Read version
if (-not (Test-Path $VersionFile)) {
    Write-Error "error: $VersionFile not found"
    exit 1
}
$Version = (Get-Content $VersionFile -Raw).Trim()
$Tag = "windows/v$Version"
Write-Host "version: $Version (tag: $Tag)"

# 2. Check tag doesn't already exist locally
$LocalTag = git tag -l $Tag
if ($LocalTag) {
    Write-Error "error: tag $Tag already exists locally"
    exit 1
}

# 3. Check tag doesn't exist on remote
$RemoteTag = git ls-remote --tags origin "refs/tags/$Tag" 2>$null
if ($RemoteTag) {
    Write-Error "error: tag $Tag already exists on remote"
    exit 1
}
Write-Host "ok: tag $Tag does not exist"

# 4. Check working tree is clean
$Status = git status --porcelain
if ($Status) {
    Write-Error "error: working tree is not clean — commit changes first"
    git status --short
    exit 1
}
Write-Host "ok: working tree clean"

if ($DryRun) {
    Write-Host ""
    Write-Host "=== DRY RUN COMPLETE ==="
    Write-Host "all pre-conditions passed. Run without --dry-run to execute."
    exit 0
}

# 5. Build
Write-Host ""
Write-Host "building..."
$BuildScript = Join-Path $RepoRoot "scripts\build-windows-installer.ps1"
& powershell -ExecutionPolicy Bypass -File $BuildScript
if ($LASTEXITCODE -ne 0) { exit 1 }

# 6. Verify Velopack output
$OutputDir = Join-Path $RepoRoot "releases\windows"
$Assets = Get-ChildItem -Path $OutputDir -File
if ($Assets.Count -eq 0) {
    Write-Error "error: no files found in $OutputDir"
    exit 1
}
Write-Host "ok: found $($Assets.Count) release assets"

# 7. Create annotated tag and push
git tag -a $Tag -m $Tag
git push origin $Tag
Write-Host "ok: tag $Tag pushed"

# 8. Create GitHub release with all Velopack assets
$AssetPaths = $Assets | ForEach-Object { $_.FullName }
gh release create $Tag @AssetPaths `
    --title "Windows v$Version" `
    --notes "## Windows Release $Version`n`nInstaller for Windows (x64)."

if ($LASTEXITCODE -ne 0) {
    Write-Error "error: failed to create GitHub release"
    exit 1
}

Write-Host ""
Write-Host "release $Tag created with $($Assets.Count) assets attached"
