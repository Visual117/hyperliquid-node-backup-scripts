#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives/node_order_statuses"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"
LOG_FILE="/var/log/hl_archive_cleanup_node_order_statuses.log"

echo "===== $(date -u) ARCHIVE CLEANUP node_order_statuses START =====" | tee -a "$LOG_FILE"

# Find any backed-up archives in the success log
grep -E 'node_order_statuses_[0-9]{4}-[0-9]{2}-[0-9]{2}\.tar\.zst' "$SUCCESS_LOG" | \
while read -r tarfile; do
  # Delete the archive if it still exists
  if [[ -f "$tarfile" ]]; then
    echo "[INFO] Deleting archive: $tarfile" | tee -a "$LOG_FILE"
    rm -f "$tarfile"
  fi

  # Delete its .done marker as well
  done_marker="${tarfile%.tar.zst}.done"
  if [[ -f "$done_marker" ]]; then
    echo "[INFO] Deleting marker: $done_marker" | tee -a "$LOG_FILE"
    rm -f "$done_marker"
  fi
done

echo "===== $(date -u) ARCHIVE CLEANUP node_order_statuses END =====" | tee -a "$LOG_FILE"
