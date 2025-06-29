#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives/node_order_statuses"
LOG_FILE="/var/log/hl_idrive_backup_node_order_statuses.log"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"
IDRIVE_CLI="/opt/IDriveForLinux/bin/idrive"

echo "===== $(date -u) BACKUP node_order_statuses START =====" | tee -a "$LOG_FILE"

find "$ARCHIVE_DIR" -type f -name 'node_order_statuses_*.tar.zst' | sort | while read -r tarfile; do
  base="${tarfile%.tar.zst}"
  # only back up if it’s marked done and not in-progress
  if [[ -f "${base}.done" && ! -f "${base}.inprogress" ]]; then
    echo "[INFO] Backing up $tarfile" | tee -a "$LOG_FILE"
    $IDRIVE_CLI --backup "$tarfile" --silent
    if [[ $? -eq 0 ]]; then
      echo "[SUCCESS] $tarfile" | tee -a "$LOG_FILE"
      echo "$tarfile" >> "$SUCCESS_LOG"
      # clear the .done marker
      rm -f "${base}.done"
    else
      echo "[ERROR] Backup failed for $tarfile" | tee -a "$LOG_FILE"
    fi
  else
    echo "[SKIP] $tarfile" | tee -a "$LOG_FILE"
  fi
done

echo "===== $(date -u) BACKUP node_order_statuses END =====" | tee -a "$LOG_FILE"
