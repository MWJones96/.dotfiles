#!/usr/bin/env bash
set -euo pipefail

note="$HOME/Obsidian/matthew-quaisr/Scratch Pad.md"
state="$HOME/.local/state/tidy-scratch-pad"
prompt="$HOME/.config/tidy-scratch-pad/prompt.md"
claude="$HOME/.local/bin/claude"

mkdir -p "$state/backups"
today=$(date -u +%F)

[ "$(cat "$state/last-run" 2>/dev/null)" = "$today" ] && [ "${1:-}" != "--force" ] && exit 0
[ -s "$note" ] || { echo "$today" > "$state/last-run"; exit 0; }

before=$(shasum -a 256 "$note" | cut -d' ' -f1)
if [ "$before" = "$(cat "$state/last-hash" 2>/dev/null)" ]; then
  echo "$today" > "$state/last-run"
  exit 0
fi

cp "$note" "$state/backups/$today.md"

tidied=$(mktemp)
trap 'rm -f "$tidied"' EXIT

"$claude" -p --safe-mode --tools "" --no-session-persistence \
  --system-prompt-file "$prompt" < "$note" > "$tidied"

[ -s "$tidied" ] || { echo "empty response, leaving note untouched" >&2; exit 1; }

if [ "$(shasum -a 256 "$note" | cut -d' ' -f1)" != "$before" ]; then
  echo "note changed while tidying, retrying next hour" >&2
  exit 1
fi

mv "$tidied" "$note"
shasum -a 256 "$note" | cut -d' ' -f1 > "$state/last-hash"
echo "$today" > "$state/last-run"
echo "$(date -u +%FT%TZ) tidied"
