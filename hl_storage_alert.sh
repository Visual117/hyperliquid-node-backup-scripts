#!/usr/bin/env bash
#
# /usr/local/bin/hl_storage_alert.sh
# — Disk-space alert via Telegram, self-loading env, full logging

set -euo pipefail

LOG=/var/log/hl_storage_alert.log

touch "$LOG"
exec &>>"$LOG"

echo "===== $(date -u '+%Y-%m-%dT%H:%M:%SZ') Starting disk-alert check ====="

# Load secrets
if [[ -r /etc/telegram.env ]]; then
  source /etc/telegram.env
else
  echo "ERROR: /etc/telegram.env missing or unreadable"
  exit 1
fi

echo "LOADED ENV: TELEGRAM_BOT_TOKEN='${TELEGRAM_BOT_TOKEN}'"
echo "LOADED ENV: TELEGRAM_CHAT_ID='${TELEGRAM_CHAT_ID}'"

# Compute usage
RAW=$(df -BG /data | awk 'NR==2 {print $3}')
USED_GB=${RAW%G}
if [[ -z "$USED_GB" ]]; then
  echo "ERROR: could not parse df output: '$RAW'"
  exit 1
fi
echo "DEBUG: Used /data = ${USED_GB}GB"

# Threshold check
THRESHOLD=1000
if [ "$USED_GB" -lt "$THRESHOLD" ]; then
  echo "INFO: ${USED_GB}GB < ${THRESHOLD}GB — no alert."
  exit 0
fi
echo "INFO: ${USED_GB}GB ≥ ${THRESHOLD}GB — sending alert."

# Send via curl GET + data-urlencode
TEXT="🚨 Disk alert: /data at ${USED_GB}GB ≥${THRESHOLD}GB"
HTTP_CODE=$(
  curl -s -w '%{http_code}' -o /tmp/telegram_out.json \
    -G "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${TEXT}"
)
echo "DEBUG: HTTP status $HTTP_CODE"
cat /tmp/telegram_out.json

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "ERROR: Telegram API returned $HTTP_CODE"
  exit 1
fi

echo "SUCCESS: Alert sent."
