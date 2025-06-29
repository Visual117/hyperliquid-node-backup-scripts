#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives/node_order_statuses"
SOURCE_DIR="/var/lib/hyperliquid/data/node_order_statuses/hourly"
LOG_FILE="/var/log/hl_group_and_compress_node_order_statuses.log"

# We’re sticking with level 9 for speed
ZSTD_LEVEL=9

YESTERDAY=$(date -u -d 'yesterday' +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

archive="$ARCHIVE_DIR/node_order_statuses_${YESTERDAY}.tar.zst"
marker_done="$archive.done"
marker_inprog="$archive.inprogress"

# Auto-heal any half-baked archives
if [[ -f "$archive" && ! -f "$marker_done" ]]; then
  echo "[WARN] Orphaned archive, deleting: $archive" | tee -a "$LOG_FILE"
  rm -f "$archive" "$marker_inprog"
fi

# Skip if already done
if [[ -f "$marker_done" ]]; then
  echo "[SKIP] Already handled $YESTERDAY" | tee -a "$LOG_FILE"
  exit 0
fi

# Mark in-progress, compress at level 9
touch "$marker_inprog"
echo "[INFO] Compressing node_order_statuses for $YESTERDAY (zstd -$ZSTD_LEVEL)" | tee -a "$LOG_FILE"

(
  cd "$SOURCE_DIR" \
    || { echo "[ERROR] Cannot cd to $SOURCE_DIR" | tee -a "$LOG_FILE"; exit 1; }
  tar -cf - --transform="s|.*/||" "${YESTERDAY}"*
) | zstd -"$ZSTD_LEVEL" -T0 -o "$archive"

if [[ $? -ne 0 ]]; then
  echo "[ERROR] Compression failed for $YESTERDAY" | tee -a "$LOG_FILE"
  rm -f "$marker_inprog"
  exit 1
fi

rm -f "$marker_inprog"
touch "$marker_done"
echo "[DONE] $archive" | tee -a "$LOG_FILE"
