#!/usr/bin/env bash
set -euo pipefail

# ── CONFIGURATION ────────────────────────────────────────────────────────────
WATCH_PATH="/data"
THRESHOLD_GB=940
BOT_TOKEN="8036916745:AAFJxI-Q7VHt89fF5o_OdUa9RPh0Hl-Z74Q"   # ← your bot token
CHAT_ID="[REMOVED_CHAT_ID]"                                       # ← your chat ID
# ──────────────────────────────────────────────────────────────────────────────

# Get used space in GB (integer)
USED_GB=$(df -BG "$WATCH_PATH" | awk 'NR==2 {gsub("G","",$3); print $3}')

if (( USED_GB >= THRESHOLD_GB )); then
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
  TEXT="🚨 *Disk Alert*\nPath: \`$WATCH_PATH\`\nUsed: *${USED_GB} GB* ≥ *${THRESHOLD_GB} GB*\nTime: ${TIMESTAMP}"
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d parse_mode=Markdown \
    -d text="$TEXT" >/dev/null
fi
