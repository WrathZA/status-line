# status-line

My personal Claude Code statusline configuration — versioned and maintained here so I have a history of changes and a single place to make updates.

This repo is public as a reference. I'm the only one making changes.

## What it shows

A typical render on a feature branch:

```
/home/bm/code/status-line (feat/15-issue-link*↑1) #15 [Opus 4.7] ctx: 45% gh: 1 open / 7 closed | P0:1 | 2 PRs (1 draft)
```

### Anatomy

| Segment | Format | Color | When it appears |
|---|---|---|---|
| Working directory | absolute path | blue | always |
| Branch | `(name)` | cyan | inside a git repo |
| Dirty marker | `*` after branch | yellow | uncommitted changes |
| Ahead / behind | `↑N` / `↓N` after branch | yellow | branch diverges from upstream |
| Issue link | `#N` as a clickable OSC 8 hyperlink | blue | branch matches `feat/N-…` / `fix/issue-N` / `N-…`, or the open PR closes an issue (PR-linked wins) |
| Model | `[name]` | purple | always |
| Context % | `ctx: N%` | green < 60, yellow 60–79, red ≥ 80 | always |
| GH summary | `gh: X open / Y closed \| P0:n P1:n P2:n \| Z PRs (W draft)` | blue | inside a GitHub repo with `gh` installed |

Anything that can't be resolved (no git repo, no remote, `gh` missing, no issue inferable) is skipped silently — the statusline stays clean.

## Install

```
bash statusline-command.sh --install
```

This symlinks the script into `~/.claude/` and wires `statusLine` in `~/.claude/settings.json`. Idempotent — safe to re-run.

## Dependencies

- `bash`, `jq`, `git` — required
- `gh` — optional; needed for the issue link and the `gh:` summary block

## Workflow

Changes go through [github-weld](https://github.com/WrathZA/github-weld) — structured issues, correctly-named branches, and a session export at every merge commit. For a repo that's just one config file, that might seem like overkill — but the point is the audit trail. Each PR captures *why* a change was made, not just what changed.

---

*Ship, file, and clear.*
