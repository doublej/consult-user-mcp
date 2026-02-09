$ErrorActionPreference = "Stop"

# Thin wrapper — delegates to build-windows-installer.ps1
$Script = Join-Path $PSScriptRoot "build-windows-installer.ps1"
& powershell -ExecutionPolicy Bypass -File $Script
exit $LASTEXITCODE
