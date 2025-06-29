#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives/periodic_abci_states"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"
LOG_FILE="/var/log/hl_archive_cleanup_periodic_abci_states.log"

echo "===== $(date -u) ARCHIVE CLEANUP periodic_abci_states START =====" | tee -a "$LOG_FILE"

# Look for .tar.zst entries in the success log
grep -E 'periodic_abci_states_[0-9]{4}-[0-9]{2}-[0-9]{2}\.tar\.zst' "$SUCCESS_LOG" | \
while read -r tarfile; do
  # only proceed if the archive still exists
  if [[ -f "$tarfile" ]]; then
    echo "[INFO] Deleting archive: $tarfile" | tee -a "$LOG_FILE"
    rm -f "$tarfile"
  fi

  # also remove the .done marker if present
  done_marker="${tarfile%.tar.zst}.done"
  if [[ -f "$done_marker" ]]; then
    echo "[INFO] Deleting marker: $done_marker" | tee -a "$LOG_FILE"
    rm -f "$done_marker"
  fi
done

echo "===== $(date -u) ARCHIVE CLEANUP periodic_abci_states END =====" | tee -a "$LOG_FILE"
