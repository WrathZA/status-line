# GitHub Weld — CLI Conventions

Hard-won rules for using `gh` and `git` inside Claude Code agent sessions. These constraints exist because Claude Code's permission and safety systems interact with shell execution in non-obvious ways. Follow them precisely.

## Bash execution

**NEVER chain commands with `&&` or `;`** — Claude Code's safety check fires on ambiguous multi-command calls and interrupts the session mid-flow. Run each command as a separate Bash tool call.

**NEVER use `|` (pipe) in Bash tool calls** — Claude Code stops execution when it encounters a pipe, interrupting the agent without warning. If you need piped output, write to a temp file with `>` and read it back with the Read tool. Note: `|` in markdown table syntax is unaffected.

**NEVER use `$(...)` command substitution** — Claude Code's permission system prompts on `$()` during execution, interrupting the agent unnecessarily. Use fixed paths under `.weld/tmp/` with the Write tool instead of capturing command output into variables.

**NEVER use bash heredoc (`cat > file << 'EOF'`) for file content containing `#`-prefixed lines** — headers trigger Claude Code's security check on every execution. Use the Write tool to write file content instead.

**NEVER use quoted strings as separator arguments** (e.g. `echo "---"`) — use blank lines or comments instead.

## GitHub CLI body content

**NEVER pass multiline content containing `#`-prefixed lines as an inline `gh` argument** — headers trigger an un-suppressible permission check prompt. This applies to `--body "..."`, `$()`, and backtick substitution alike.

**ALWAYS write body content with the Write tool** to a fixed path under `.weld/tmp/` (e.g. `.weld/tmp/issue-body.md`), pass via `--body-file <path>`, then delete with a Bash `rm` call after use.

```
# Pattern for any gh command with multiline body:
Write tool → .weld/tmp/<name>.md
gh <command> --body-file .weld/tmp/<name>.md
rm .weld/tmp/<name>.md
```

## Temp files

**NEVER use `mktemp` or `$(mktemp ...)`** — use fixed paths under `.weld/tmp/` with the Write tool. This keeps temp files visible and avoids platform-dependent `/tmp/` paths.

**NEVER use `python3 -c "import os; os.makedirs(...)"` to pre-create directories** — the Write tool creates parent directories implicitly when writing any file.

## Tool preference

**Prefer built-in Claude Code tools over external runtimes:**
- File search → Glob (not `find`)
- Content search → Grep (not `grep`/`rg`)
- Read files → Read tool (not `cat`)
- Write files → Write tool (not `echo >` or heredoc)
- Edit files → Edit tool (not `sed`/`awk`)

Use external tools (`python3`, `jq`, `curl`) only when no built-in equivalent exists.

## Skill UX

**Use single-keypress prompts for user choices** — when a skill needs the user to pick between options, present lettered choices (e.g. `Scope: (r)epo or (g)ithub-wide? [r]`) with a sensible default on Enter. Never design CLI-style flags for skill workflows.

## Git workflow

**NEVER commit directly to `main` or `master`** — create a branch first, every time, without exception.

**NEVER squash-merge before format and tests are clean** — a broken merge to main blocks all future work on that repo.

**Run the project's format command before every commit** — reformatting commits create noisy diffs that obscure intent. If no format command is documented, ask.
