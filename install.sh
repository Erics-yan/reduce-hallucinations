#!/usr/bin/env bash
# claude-factcheck installer (macOS / Linux / Git Bash)
# Idempotent: safe to re-run. Appends rules block to ~/.claude/CLAUDE.md
# between <!-- factcheck:begin --> and <!-- factcheck:end --> markers.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
SKILL_SRC="$SCRIPT_DIR/skills/factcheck/SKILL.md"
RULES_SRC="$SCRIPT_DIR/CLAUDE.md"
SKILL_DST_DIR="$CLAUDE_DIR/skills/factcheck"
SKILL_DST="$SKILL_DST_DIR/SKILL.md"
RULES_DST="$CLAUDE_DIR/CLAUDE.md"

BEGIN_MARKER='<!-- factcheck:begin -->'
END_MARKER='<!-- factcheck:end -->'

echo "==> claude-factcheck installer"
echo "    Target: $CLAUDE_DIR"

if [ ! -f "$SKILL_SRC" ] || [ ! -f "$RULES_SRC" ]; then
  echo "ERROR: source files missing. Run this script from the cloned repo root." >&2
  exit 1
fi

mkdir -p "$SKILL_DST_DIR"

# 1. Install skill
if [ -f "$SKILL_DST" ] && ! cmp -s "$SKILL_SRC" "$SKILL_DST"; then
  backup="$SKILL_DST.bak.$(date +%s)"
  cp "$SKILL_DST" "$backup"
  echo "    Existing skill backed up to: $backup"
fi
cp "$SKILL_SRC" "$SKILL_DST"
echo "    [ok] skill installed: $SKILL_DST"

# 2. Install / update CLAUDE.md rules block
touch "$RULES_DST"
if grep -qF "$BEGIN_MARKER" "$RULES_DST"; then
  # Existing block: replace between markers in-place
  tmp="$(mktemp)"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v srcfile="$RULES_SRC" '
    BEGIN { skip = 0 }
    $0 ~ begin { skip = 1; while ((getline line < srcfile) > 0) print line; close(srcfile); next }
    $0 ~ end   { skip = 0; next }
    skip == 0  { print }
  ' "$RULES_DST" > "$tmp"
  mv "$tmp" "$RULES_DST"
  echo "    [ok] CLAUDE.md rules block updated in-place"
else
  # No block yet: append, with a blank line separator if file is non-empty
  if [ -s "$RULES_DST" ]; then
    printf '\n\n' >> "$RULES_DST"
  fi
  cat "$RULES_SRC" >> "$RULES_DST"
  echo "    [ok] CLAUDE.md rules block appended"
fi

echo
echo "==> Done."
echo "    Open a new Claude Code session — the factcheck protocol is now active by default."
echo "    Manual trigger remains available: /factcheck  or  /factcheck <question>"
