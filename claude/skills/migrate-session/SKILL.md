---
name: migrate-session
description: Use when the user wants to move or continue a Claude Code conversation on a different account (e.g. "switch this session from personal to chairon", "I ran out of tokens on my personal account, move this to work"). Copies the session transcript between account config directories so it can be resumed under another login.
---

# Migrate a Claude Code session between accounts

Maksim runs Claude Code under two separate accounts, each with its own
`CLAUDE_CONFIG_DIR`:

| alias      | `CLAUDE_CONFIG_DIR`      | account                     |
|------------|--------------------------|-----------------------------|
| `personal` | `~/.claude-personal`     | `masyahook@gmail.com`        |
| `chairon`  | `~/.claude-chairon`      | `chairon.io.23@gmail.com`    |

A session transcript (`~/.claude-*/projects/<project-key>/<session-id>.jsonl`)
is just a file on disk — it isn't tied to an account. "Migrating" a session
means copying that file into the target account's config directory so it can
be resumed there with `claude --resume`.

## Steps

1. Confirm the current account and the target account. The current account
   is whatever `CLAUDE_CONFIG_DIR` is set to in this shell:
   ```bash
   echo "$CLAUDE_CONFIG_DIR"
   ```
2. Run the migration script from the project root (it must run from the same
   working directory as the session you're migrating, since sessions are
   keyed by cwd):
   ```bash
   .claude/skills/migrate-session/scripts/migrate_session.sh migrate <personal|chairon>
   ```
   By default it migrates the most recently modified session for the current
   directory. To migrate a specific session, pass its id as a second
   argument (find it with `ls -t "$CLAUDE_CONFIG_DIR/projects/$(pwd | tr '/.' '-')"`).
3. The script prints the exact resume command, e.g.:
   ```bash
   CLAUDE_CONFIG_DIR=~/.claude-chairon claude --resume <session-id>
   ```
   Hand this command to the user (or run it in a new terminal/shell) —
   the running process can't switch its own `CLAUDE_CONFIG_DIR` mid-session,
   so this always starts a fresh `claude` process pointed at the other
   account.
4. `migrate_session.sh list` shows both account aliases and which email each
   one is currently logged in as — use it to sanity-check before migrating,
   or if the user asks "which account am I on".

## Before migrating: close any open resume on the destination

**Close every `claude --resume <session-id>` process for this session on the
destination account before migrating (this applies to a migrate-back just as
much as the first migration).** Claude Code periodically rewrites a session's
`.jsonl` from its own in-memory transcript. If a process already has that
session open on the destination side, its next autosave silently overwrites
your freshly-copied file with its own (stale) history — the copy appears to
succeed but the old conversation reappears. The script refuses to overwrite a
destination file that's currently held open (via `lsof`) and errors out
instead; if you hit that error, quit the other `claude` process first, then
retry.

## Limitations

- Only the conversation transcript is copied. Per-account state (allowed
  tools, MCP server auth, trust dialogs) is NOT migrated — the destination
  account will re-prompt for those independently.
- The source file is left in place (copy, not move), so the original account
  still has the conversation too.
- Subagent transcripts stored in the sibling `<session-id>/subagents/*.jsonl`
  directory are NOT copied — only the top-level `<session-id>.jsonl` file is.
