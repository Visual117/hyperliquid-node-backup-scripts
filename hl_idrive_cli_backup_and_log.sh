#!/bin/bash

ARCHIVE_DIR="/data/hyperliquid-archives"
IDRIVE_CLI="/opt/IDriveForLinux/bin/idrive"
UPLOAD_LOG="/tmp/uploaded_tars.txt"

# Only pick .tar.zst files with a matching .done and NOT .inprogress/_filelist.txt
find "$ARCHIVE_DIR" -maxdepth 1 -type f -name 'group_*.tar.zst' | sort | while read -r tarfile; do
    base="${tarfile%.tar.zst}"
    if [ -f "${base}.done" ] && [ ! -f "${base}.inprogress" ] && [ ! -f "${base}_filelist.txt" ]; then
        # Extra check: is the file open by any process?
        if ! lsof "$tarfile" >/dev/null 2>&1; then
            echo "Backing up: $tarfile"
            # Run the backup and capture output
            output=$("$IDRIVE_CLI" --backup "$tarfile" --silent 2>&1)
            # Check output for backup success, adjust if you see a different success string!
            if echo "$output" | grep -qi "success"; then
                echo "$tarfile" | sudo tee -a "$UPLOAD_LOG" >/dev/null
                echo "[LOGGED] $tarfile"
            else
                echo "[FAILED] $tarfile - Output: $output"
            fi
        else
            echo "Skipping (open by a process): $tarfile"
        fi
    else
        echo "Skipping (not finished): $tarfile"
    fi
done
