#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives/periodic_abci_states"
LOG_FILE="/var/log/hl_idrive_backup_periodic_abci_states.log"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"
IDRIVE_CLI="/opt/IDriveForLinux/bin/idrive"

echo "===== $(date) BACKUP periodic_abci_states START =====" | tee -a "$LOG_FILE"

find "$ARCHIVE_DIR" -type f -name 'periodic_abci_states_*.tar.zst' | sort | while read tarfile; do
  base="${tarfile%.tar.zst}"
  if [[ -f "${base}.done" && ! -f "${base}.inprogress" ]]; then
    echo "[INFO] Backing up $tarfile" | tee -a "$LOG_FILE"
    $IDRIVE_CLI --backup "$tarfile" --silent
    if [[ $? -eq 0 ]]; then
      echo "[SUCCESS] $tarfile" | tee -a "$LOG_FILE"
      echo "$tarfile" >> "$SUCCESS_LOG"
      rm -f "${base}.done"
    else
      echo "[ERROR] Backup failed for $tarfile" | tee -a "$LOG_FILE"
    fi
  else
    echo "[SKIP] $tarfile" | tee -a "$LOG_FILE"
  fi
done

echo "===== $(date) BACKUP periodic_abci_states END =====" | tee -a "$LOG_FILE"
