#!/usr/bin/env bash
# claude-factcheck uninstaller (macOS / Linux / Git Bash)
# Removes the rules block from ~/.claude/CLAUDE.md and deletes the skill dir.
# Preserves any other content in CLAUDE.md.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
SKILL_DST_DIR="$CLAUDE_DIR/skills/factcheck"
RULES_DST="$CLAUDE_DIR/CLAUDE.md"
BEGIN_MARKER='<!-- factcheck:begin -->'
END_MARKER='<!-- factcheck:end -->'

echo "==> claude-factcheck uninstaller"
echo "    Target: $CLAUDE_DIR"

# 1. Remove skill dir
if [ -d "$SKILL_DST_DIR" ]; then
  rm -rf "$SKILL_DST_DIR"
  echo "    [ok] removed: $SKILL_DST_DIR"
else
  echo "    [skip] skill dir not present"
fi

# 2. Strip rules block from CLAUDE.md
if [ -f "$RULES_DST" ] && grep -qF "$BEGIN_MARKER" "$RULES_DST"; then
  tmp="$(mktemp)"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    BEGIN { skip = 0 }
    $0 ~ begin { skip = 1; next }
    $0 ~ end   { skip = 0; next }
    skip == 0  { print }
  ' "$RULES_DST" > "$tmp"
  # Trim trailing blank lines
  awk 'NF {blank=0; for(i=0;i<hold;i++) print ""; print; next} {hold++}' "$tmp" > "$RULES_DST"
  rm -f "$tmp"
  echo "    [ok] rules block removed from $RULES_DST"
else
  echo "    [skip] no factcheck block in $RULES_DST"
fi

echo
echo "==> Done."
