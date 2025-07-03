#!/usr/bin/env bash
#
# /usr/local/bin/hl_group_and_compress_node_order_statuses_locked.sh
# — Compress yesterday’s node_order_statuses with live progress,
#   logging, and .inprogress/.done markers

set -euo pipefail

LOG=/var/log/hl_group_and_compress_node_order_statuses.log
SRC_BASE=/var/lib/hyperliquid/data/node_order_statuses/hourly
ARCHIVE_DIR=/data/hyperliquid-archives/node_order_statuses

YESTERDAY=$(date -u -d 'yesterday' +%Y%m%d)
SRC_DIR=${SRC_BASE}/${YESTERDAY}
ARCHIVE=${ARCHIVE_DIR}/node_order_statuses_${YESTERDAY}.tar.zst
INPROG=${ARCHIVE}.inprogress
DONE=${ARCHIVE}.done

mkdir -p "$ARCHIVE_DIR"
echo "===== $(date -u '+%Y-%m-%dT%H:%M:%SZ') Compress node_order_statuses for $YESTERDAY =====" | tee -a "$LOG"

# Skip if already done
if [[ -f "$DONE" ]]; then
  echo "[SKIP] Already handled $YESTERDAY" | tee -a "$LOG"
  exit 0
fi

# Remove any orphan
if [[ -f "$INPROG" || -f "$ARCHIVE" ]]; then
  echo "[WARN] Removing orphan $INPROG/$ARCHIVE" | tee -a "$LOG"
  rm -f "$INPROG" "$ARCHIVE"
fi

# Verify source exists
if [[ ! -d "$SRC_DIR" ]]; then
  echo "[ERROR] Source dir not found: $SRC_DIR" | tee -a "$LOG"
  exit 1
fi

# Start
touch "$INPROG"
echo "[INFO] Starting compression with live progress…" | tee -a "$LOG"

# Compute size for pv
SIZE=$(du -sb "$SRC_DIR" | awk '{print $1}')

tar -cf - -C "$SRC_BASE" "$YESTERDAY" \
  | pv -f -s "$SIZE" -p -e -r -b \
  | zstd --progress -v -9 -T0 -o "$ARCHIVE"

# Check exit codes
if [[ ${PIPESTATUS[0]} -ne 0 || ${PIPESTATUS[2]} -ne 0 ]]; then
  echo "[ERROR] Compression failed for $YESTERDAY" | tee -a "$LOG"
  rm -f "$INPROG"
  exit 1
fi

rm -f "$INPROG"
touch "$DONE"
echo "[DONE] $ARCHIVE" | tee -a "$LOG"
