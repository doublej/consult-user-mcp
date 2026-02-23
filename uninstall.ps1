param(
    [switch]$KeepData,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$InstallRoot = Join-Path $env:LOCALAPPDATA "ConsultUserMCP"
$UpdateExe = Join-Path $InstallRoot "Update.exe"
$AppDataDir = Join-Path $env:APPDATA "ConsultUserMCP"
$ProjectsFile = Join-Path $env:USERPROFILE ".config\consult-user-mcp\projects.json"
$ProjectsDir = Split-Path -Parent $ProjectsFile

function Write-Step {
    param([string]$Message)
    Write-Host "* $Message"
}

function Remove-FileIfExists {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }

    if ($DryRun) {
        Write-Host "  [dry-run] remove $Path"
        return
    }

    Remove-Item -LiteralPath $Path -Force
    Write-Host "  removed $Path"
}

function Remove-DirectoryIfExists {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }

    if ($DryRun) {
        Write-Host "  [dry-run] remove $Path"
        return
    }

    Remove-Item -LiteralPath $Path -Recurse -Force
    Write-Host "  removed $Path"
}

function Remove-EmptyDirectory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }

    $hasEntries = Get-ChildItem -LiteralPath $Path -Force | Select-Object -First 1
    if ($hasEntries) { return }

    if ($DryRun) {
        Write-Host "  [dry-run] remove empty dir $Path"
        return
    }

    Remove-Item -LiteralPath $Path -Force
}

function Remove-McpJsonEntry {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }

    $raw = Get-Content -LiteralPath $Path -Raw
    $json = $null
    try {
        $json = $raw | ConvertFrom-Json
    } catch {
        Write-Warning "Skipped invalid JSON: $Path"
        return
    }

    if ($null -eq $json.mcpServers) { return }
    if ($json.mcpServers.PSObject.Properties.Name -notcontains "consult-user-mcp") { return }

    $json.mcpServers.PSObject.Properties.Remove("consult-user-mcp")
    if ($json.mcpServers.PSObject.Properties.Count -eq 0) {
        $json.PSObject.Properties.Remove("mcpServers")
    }

    if ($DryRun) {
        Write-Host "  [dry-run] update $Path"
    } else {
        $updated = $json | ConvertTo-Json -Depth 32
        Set-Content -LiteralPath $Path -Value $updated -Encoding UTF8
    }

    Write-Host "  removed MCP entry from $Path"
}

function Remove-McpTomlSection {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }

    $raw = Get-Content -LiteralPath $Path -Raw
    $updated = [Regex]::Replace(
        $raw,
        '(?ms)^\s*\[mcp_servers\.consult-user-mcp\][\s\S]*?(?=^\s*\[|\z)',
        ''
    )
    if ($updated -eq $raw) { return }

    $updated = [Regex]::Replace($updated, '(\r?\n){3,}', "`n`n").Trim()
    if ($updated.Length -gt 0) { $updated += "`n" }

    if ($DryRun) {
        Write-Host "  [dry-run] update $Path"
    } else {
        Set-Content -LiteralPath $Path -Value $updated -Encoding UTF8
    }

    Write-Host "  removed MCP section from $Path"
}

function Remove-BasePromptSection {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }

    $raw = Get-Content -LiteralPath $Path -Raw
    $updated = [Regex]::Replace(
        $raw,
        '(?s)\s*<consult-user-mcp-baseprompt version="[^"]+">\s*.*?\s*</consult-user-mcp-baseprompt>\s*',
        "`n`n"
    )
    $updated = [Regex]::Replace(
        $updated,
        '(?ms)^\s*# Consult User MCP[\s\S]*?(?=^#[^#]|\z)',
        ''
    )
    if ($updated -eq $raw) { return }

    $updated = [Regex]::Replace($updated, '(\r?\n){3,}', "`n`n").Trim()

    if ($updated.Length -eq 0) {
        if ($DryRun) {
            Write-Host "  [dry-run] remove $Path"
        } else {
            Remove-Item -LiteralPath $Path -Force
        }
        Write-Host "  removed empty file $Path"
        return
    }

    if ($DryRun) {
        Write-Host "  [dry-run] update $Path"
    } else {
        Set-Content -LiteralPath $Path -Value ($updated + "`n") -Encoding UTF8
    }

    Write-Host "  removed base prompt section from $Path"
}

Write-Step "Removing MCP config entries and base prompt sections"
Remove-McpJsonEntry (Join-Path $env:APPDATA "Claude\claude_desktop_config.json")
Remove-McpJsonEntry (Join-Path $env:USERPROFILE ".claude.json")
Remove-McpTomlSection (Join-Path $env:USERPROFILE ".codex\config.toml")
Remove-BasePromptSection (Join-Path $env:USERPROFILE ".claude\CLAUDE.md")
Remove-BasePromptSection (Join-Path $env:USERPROFILE ".codex\AGENTS.md")

Write-Step "Disabling startup entry"
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if ($DryRun) {
    Write-Host "  [dry-run] remove startup key value ConsultUserMCP"
} else {
    Remove-ItemProperty -Path $runKey -Name "ConsultUserMCP" -ErrorAction SilentlyContinue
    Write-Host "  startup entry removed (if it existed)"
}

Write-Step "Removing installed app"
if (Test-Path -LiteralPath $UpdateExe -PathType Leaf) {
    if ($DryRun) {
        Write-Host "  [dry-run] run `"$UpdateExe --uninstall`""
    } else {
        try {
            $process = Start-Process -FilePath $UpdateExe -ArgumentList "--uninstall" -PassThru -Wait
            Write-Host "  ran Update.exe --uninstall (exit code $($process.ExitCode))"
        } catch {
            Write-Warning "Failed to run Update.exe uninstall: $($_.Exception.Message)"
        }
    }
}
Remove-DirectoryIfExists $InstallRoot

if (-not $KeepData) {
    Write-Step "Removing app data"
    Remove-DirectoryIfExists $AppDataDir
    Remove-FileIfExists $ProjectsFile
    Remove-EmptyDirectory $ProjectsDir
} else {
    Write-Step "Keeping app data (-KeepData)"
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete."
} else {
    Write-Host "Uninstall complete."
}
