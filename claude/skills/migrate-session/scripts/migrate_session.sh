#!/usr/bin/env bash
# Copy a Claude Code session transcript between account config directories
# (e.g. ~/.claude-personal <-> ~/.claude-chairon) so a conversation can be
# resumed under a different account.
set -euo pipefail

ACCOUNTS_HELP="known accounts: personal -> ~/.claude-personal, chairon -> ~/.claude-chairon"

resolve_dir() {
  case "$1" in
    personal) echo "$HOME/.claude-personal" ;;
    chairon) echo "$HOME/.claude-chairon" ;;
    /*) echo "$1" ;;
    *) echo "unknown account alias '$1'. $ACCOUNTS_HELP" >&2; exit 1 ;;
  esac
}

account_email() {
  local dir="$1"
  python3 -c "
import json
with open('$dir/.claude.json') as f:
    data = json.load(f)
print(data.get('oauthAccount', {}).get('emailAddress', '(unknown)'))
"
}

project_key() {
  pwd | tr '/.' '-'
}

cmd_list() {
  for alias in personal chairon; do
    dir="$(resolve_dir "$alias")"
    if [[ -f "$dir/.claude.json" ]]; then
      echo "$alias -> $dir ($(account_email "$dir"))"
    else
      echo "$alias -> $dir (not set up)"
    fi
  done
}

cmd_migrate() {
  local target="$1"
  local session_id="${2:-}"

  : "${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR is not set - cannot determine the source account}"
  local source_dir="$CLAUDE_CONFIG_DIR"
  local dest_dir
  dest_dir="$(resolve_dir "$target")"

  if [[ "$source_dir" == "$dest_dir" ]]; then
    echo "source and target account are the same ($dest_dir) - nothing to migrate" >&2
    exit 1
  fi

  local key
  key="$(project_key)"
  local source_project_dir="$source_dir/projects/$key"

  if [[ ! -d "$source_project_dir" ]]; then
    echo "no session directory found at $source_project_dir" >&2
    exit 1
  fi

  if [[ -z "$session_id" ]]; then
    local latest
    latest="$(ls -t "$source_project_dir"/*.jsonl 2>/dev/null | head -1)"
    if [[ -z "$latest" ]]; then
      echo "no .jsonl session files found in $source_project_dir" >&2
      exit 1
    fi
    session_id="$(basename "$latest" .jsonl)"
  fi

  local source_file="$source_project_dir/$session_id.jsonl"
  if [[ ! -f "$source_file" ]]; then
    echo "session file not found: $source_file" >&2
    exit 1
  fi

  local dest_project_dir="$dest_dir/projects/$key"
  local dest_file="$dest_project_dir/$session_id.jsonl"

  # Claude Code periodically rewrites a session's .jsonl from its own
  # in-memory transcript. If a `claude --resume` process for this session is
  # still open on the destination account, its next autosave will silently
  # overwrite our copy with its own (stale) history. Refuse in that case.
  command -v lsof >/dev/null || { echo "lsof not found - required to detect open destination files" >&2; exit 1; }
  if [[ -f "$dest_file" ]] && lsof "$dest_file" >/dev/null 2>&1; then
    echo "refusing to migrate: $dest_file is open by a running process" >&2
    echo "close any 'claude --resume $session_id' process on the destination account first, then retry" >&2
    exit 1
  fi

  mkdir -p "$dest_project_dir"
  cp "$source_file" "$dest_file"

  echo "copied session $session_id"
  echo "  from: $source_file"
  echo "  to:   $dest_file"
  echo
  echo "resume it with:"
  echo "  CLAUDE_CONFIG_DIR=$dest_dir claude --resume $session_id"
}

main() {
  local subcommand="${1:-}"
  case "$subcommand" in
    list)
      cmd_list
      ;;
    migrate)
      shift
      if [[ $# -lt 1 ]]; then
        echo "usage: migrate_session.sh migrate <personal|chairon> [session_id]" >&2
        exit 1
      fi
      cmd_migrate "$@"
      ;;
    *)
      echo "usage: migrate_session.sh <list|migrate> ..." >&2
      exit 1
      ;;
  esac
}

main "$@"
