#!/bin/bash
set -euo pipefail

KEEP_DATA=0
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --keep-data)
      KEEP_DATA=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: uninstall.sh [--keep-data] [--dry-run]

Options:
  --keep-data   Keep settings/history/project data files
  --dry-run     Print actions without modifying files
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

APP_PATH="/Applications/Consult User MCP.app"
APP_SUPPORT_PATH="$HOME/Library/Application Support/ConsultUserMCP"
PROJECTS_PATH="$HOME/.config/consult-user-mcp/projects.json"

print_step() {
  echo "* $1"
}

remove_path() {
  local target="$1"
  if [ ! -e "$target" ]; then
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] remove $target"
    return
  fi

  if rm -rf "$target"; then
    echo "  removed $target"
  else
    echo "  warning: could not remove $target" >&2
  fi
}

remove_if_empty_dir() {
  local target="$1"
  if [ ! -d "$target" ]; then
    return
  fi

  if [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] remove empty dir $target"
    return
  fi

  rmdir "$target" || true
}

print_step "Removing MCP config entries and base prompt sections"
CUMCP_DRY_RUN="$DRY_RUN" python3 <<'PY'
from __future__ import annotations

import json
import os
import re
from pathlib import Path

dry_run = os.environ.get("CUMCP_DRY_RUN") == "1"
home = Path.home()


def write_file(path: Path, content: str) -> None:
    if dry_run:
        print(f"  [dry-run] update {path}")
        return
    path.write_text(content, encoding="utf-8")


def remove_file(path: Path) -> None:
    if dry_run:
        print(f"  [dry-run] remove {path}")
        return
    path.unlink(missing_ok=True)


def remove_mcp_json(path: Path) -> None:
    if not path.exists():
        return

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        print(f"  warning: skipped invalid JSON {path}: {exc}")
        return

    mcp_servers = data.get("mcpServers")
    if not isinstance(mcp_servers, dict) or "consult-user-mcp" not in mcp_servers:
        return

    del mcp_servers["consult-user-mcp"]
    if not mcp_servers:
        data.pop("mcpServers", None)

    write_file(path, json.dumps(data, indent=2) + "\n")
    print(f"  removed MCP entry from {path}")


def remove_mcp_toml(path: Path) -> None:
    if not path.exists():
        return

    content = path.read_text(encoding="utf-8")
    updated = re.sub(
        r"(?ms)^\s*\[mcp_servers\.consult-user-mcp\][\s\S]*?(?=^\s*\[|\Z)",
        "",
        content,
    )
    if updated == content:
        return

    updated = re.sub(r"(\r?\n){3,}", "\n\n", updated).strip()
    if updated:
        updated += "\n"
    write_file(path, updated)
    print(f"  removed MCP section from {path}")


def remove_prompt_section(path: Path) -> None:
    if not path.exists():
        return

    content = path.read_text(encoding="utf-8")
    updated = re.sub(
        r'(?s)\s*<consult-user-mcp-baseprompt version="[^"]+">\s*.*?\s*</consult-user-mcp-baseprompt>\s*',
        "\n\n",
        content,
    )
    updated = re.sub(
        r"(?ms)^\s*# Consult User MCP[\s\S]*?(?=^#[^#]|\Z)",
        "",
        updated,
    )
    if updated == content:
        return

    cleaned = re.sub(r"(\r?\n){3,}", "\n\n", updated).strip()
    if cleaned:
        write_file(path, cleaned + "\n")
        print(f"  removed base prompt section from {path}")
    else:
        remove_file(path)
        print(f"  removed empty file {path}")


remove_mcp_json(home / "Library/Application Support/Claude/claude_desktop_config.json")
remove_mcp_json(home / ".claude.json")
remove_mcp_toml(home / ".codex/config.toml")
remove_prompt_section(home / ".claude/CLAUDE.md")
remove_prompt_section(home / ".codex/AGENTS.md")
PY

print_step "Removing app bundle"
remove_path "$APP_PATH"

if [ "$KEEP_DATA" -eq 0 ]; then
  print_step "Removing app data"
  remove_path "$APP_SUPPORT_PATH"
  remove_path "$PROJECTS_PATH"
  remove_if_empty_dir "$HOME/.config/consult-user-mcp"
else
  print_step "Keeping app data (--keep-data)"
fi

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete."
else
  echo "Uninstall complete."
fi
