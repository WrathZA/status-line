#!/bin/bash

if [ "$1" = "--install" ]; then
  REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
  CLAUDE_DIR="$HOME/.claude"
  SETTINGS="$CLAUDE_DIR/settings.json"

  # Symlink this script into ~/.claude/
  ln -sf "$REPO_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
  echo "Linked ~/.claude/statusline-command.sh"

  # Wire statusLine in settings.json (idempotent)
  if [ ! -f "$SETTINGS" ]; then
    echo "{}" > "$SETTINGS"
  fi
  tmp=$(mktemp)
  jq '.statusLine = {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "Wired statusLine in ~/.claude/settings.json"
  exit 0
fi

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

CYAN='\033[36m'
PURPLE='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

branch=""
ahead=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  raw_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ "$raw_branch" = "main" ]; then
    branch="engine"
  else
    branch="${raw_branch#project/}"
  fi
  ahead_count=$(git -C "$cwd" rev-list --no-walk=unsorted --count "origin/HEAD..HEAD" 2>/dev/null)
  if [ -n "$ahead_count" ] && [ "$ahead_count" -gt 0 ] 2>/dev/null; then
    ahead="+${ahead_count}"
  fi
fi

status=""
if [ -n "$branch" ]; then
  if [ -n "$ahead" ]; then
    status="${CYAN}(${branch} ${YELLOW}${ahead}${CYAN})${RESET}"
  else
    status="${CYAN}(${branch})${RESET}"
  fi
fi
if [ -n "$model" ]; then
  [ -n "$status" ] && status="${status} "
  status="${status}${PURPLE}[${model}]${RESET}"
fi
if [ -n "$used" ]; then
  [ -n "$status" ] && status="${status} "
  pct=$(printf '%.0f' "$used")
  if [ "$pct" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "$pct" -ge 60 ]; then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi
  status="${status}${ctx_color}ctx:${pct}%${RESET}"
fi

printf "%b" "$status"
