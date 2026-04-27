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
BLUE='\033[34m'
RESET='\033[0m'

branch=""
ahead=""
dirty=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  ahead_count=$(git -C "$cwd" rev-list --no-walk=unsorted --count "origin/HEAD..HEAD" 2>/dev/null)
  if [ -n "$ahead_count" ] && [ "$ahead_count" -gt 0 ] 2>/dev/null; then
    ahead="+${ahead_count}"
  fi
  if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
    dirty="*"
  fi
fi

gh_block=""
if [ -n "$cwd" ] && command -v gh > /dev/null 2>&1; then
  repo_json=$(cd "$cwd" && gh repo view --json nameWithOwner 2>/dev/null)
  if [ -n "$repo_json" ]; then
    nwo=$(echo "$repo_json" | jq -r '.nameWithOwner')
    owner=$(echo "$nwo" | cut -d'/' -f1)
    repo=$(echo "$nwo" | cut -d'/' -f2)
    gql=$(gh api graphql -F owner="$owner" -F repo="$repo" \
      -f query='query($owner:String!,$repo:String!){repository(owner:$owner,name:$repo){openIssues:issues(states:OPEN){totalCount}closedIssues:issues(states:CLOSED){totalCount}p0:issues(states:OPEN,labels:["P0"]){totalCount}p1:issues(states:OPEN,labels:["P1"]){totalCount}p2:issues(states:OPEN,labels:["P2"]){totalCount}openPRs:pullRequests(states:OPEN,first:100){totalCount nodes{isDraft}}}}' 2>/dev/null)
    if [ -n "$gql" ]; then
      open_i=$(echo "$gql" | jq -r '.data.repository.openIssues.totalCount')
      closed_i=$(echo "$gql" | jq -r '.data.repository.closedIssues.totalCount')
      p0=$(echo "$gql" | jq -r '.data.repository.p0.totalCount')
      p1=$(echo "$gql" | jq -r '.data.repository.p1.totalCount')
      p2=$(echo "$gql" | jq -r '.data.repository.p2.totalCount')
      open_prs=$(echo "$gql" | jq -r '.data.repository.openPRs.totalCount')
      draft_prs=$(echo "$gql" | jq -r '[.data.repository.openPRs.nodes[]|select(.isDraft==true)]|length')
      issue_str="${open_i} open / ${closed_i} closed"
      prio=""
      [ "$p0" -gt 0 ] 2>/dev/null && prio="${prio}P0:${p0} "
      [ "$p1" -gt 0 ] 2>/dev/null && prio="${prio}P1:${p1} "
      [ "$p2" -gt 0 ] 2>/dev/null && prio="${prio}P2:${p2} "
      prio="${prio% }"
      if [ "$draft_prs" -gt 0 ] 2>/dev/null; then
        pr_str="${open_prs} PRs (${draft_prs} draft)"
      else
        pr_str="${open_prs} PRs"
      fi
      if [ -n "$prio" ]; then
        gh_block="${issue_str} | ${prio} | ${pr_str}"
      else
        gh_block="${issue_str} | ${pr_str}"
      fi
    fi
  fi
fi

status=""
if [ -n "$cwd" ]; then
  status="${BLUE}$(basename "$cwd")${RESET}"
fi
if [ -n "$branch" ]; then
  if [ -n "$ahead" ] && [ -n "$dirty" ]; then
    status="${CYAN}(${branch}${YELLOW}${dirty} ${ahead}${CYAN})${RESET}"
  elif [ -n "$ahead" ]; then
    status="${CYAN}(${branch} ${YELLOW}${ahead}${CYAN})${RESET}"
  elif [ -n "$dirty" ]; then
    status="${CYAN}(${branch}${YELLOW}${dirty}${CYAN})${RESET}"
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
if [ -n "$gh_block" ]; then
  [ -n "$status" ] && status="${status} "
  status="${status}${BLUE}gh:${gh_block}${RESET}"
fi

printf "%b" "$status"
