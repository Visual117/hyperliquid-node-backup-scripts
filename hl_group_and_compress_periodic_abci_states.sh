#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives/periodic_abci_states"
SOURCE_DIR="/var/lib/hyperliquid/data/periodic_abci_states"
LOG_FILE="/var/log/hl_group_and_compress_periodic_abci_states.log"

YESTERDAY=$(date -u -d 'yesterday' +%Y%m%d)

mkdir -p "$ARCHIVE_DIR"

archive="$ARCHIVE_DIR/periodic_abci_states_${YESTERDAY}.tar.zst"
marker_done="$archive.done"
marker_inprog="$archive.inprogress"

# === Auto-heal: delete any half-baked archives & in-progress markers
if [[ -f "$archive" && ! -f "$marker_done" ]]; then
  echo "[WARN] Orphaned archive found, deleting both archive & inprog: $archive" | tee -a "$LOG_FILE"
  rm -f "$archive" "$marker_inprog"
fi

# Skip only if fully done
if [[ -f "$marker_done" ]]; then
  echo "[SKIP] Already handled $YESTERDAY" | tee -a "$LOG_FILE"
  exit 0
fi

# Mark in-progress, compress
touch "$marker_inprog"
echo "[INFO] Compressing periodic_abci_states for $YESTERDAY" | tee -a "$LOG_FILE"

tar -cf - --transform="s|.*/||" -C "$SOURCE_DIR" "${YESTERDAY}"* | \
  zstd -19 -T0 -o "$archive"

if [[ $? -ne 0 ]]; then
  echo "[ERROR] Compression failed for $YESTERDAY" | tee -a "$LOG_FILE"
  rm -f "$marker_inprog"
  exit 1
fi

# Finish up
rm -f "$marker_inprog"
touch "$marker_done"
echo "[DONE] $archive" | tee -a "$LOG_FILE"
