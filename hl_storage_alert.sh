echo "DEBUG: USED_GB=${USED_GB:-unset}, THRESHOLD_GB=${THRESHOLD_GB:-unset}, BOT=${TELEGRAM_BOT_TOKEN:-unset}, CHAT=${TELEGRAM_CHAT_ID:-unset}" >&2
#!/usr/bin/env bash
set -euo pipefail

# ── CONFIGURATION ────────────────────────────────────────────────────────────
WATCH_PATH="/data"
THRESHOLD_GB=1

# Load secrets from env; fail if not set
: "${TELEGRAM_BOT_TOKEN:?please export TELEGRAM_BOT_TOKEN}"
: "${TELEGRAM_CHAT_ID:?please export TELEGRAM_CHAT_ID}"
# ──────────────────────────────────────────────────────────────────────────────

# Get used space in GB (integer)
USED_GB=$(df -BG "$WATCH_PATH" | awk 'NR==2{gsub("G","",$3);print $3}')

if (( USED_GB >= THRESHOLD_GB )); then
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
  TEXT="🚨 *Disk Alert*\nPath: \`$WATCH_PATH\`\nUsed: *${USED_GB} GB* ≥ *${THRESHOLD_GB} GB*\nTime: ${TIMESTAMP}"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode=Markdown \
    -d text="$TEXT" >/dev/null
fi
