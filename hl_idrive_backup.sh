#!/bin/bash

ARCHIVE_DIR="/data/hyperliquid-archives"
IDRIVE_CLI="/opt/IDriveForLinux/bin/idrive"

# Loop over all group_*.tar.zst files in the archive directory
find "$ARCHIVE_DIR" -maxdepth 1 -type f -name 'group_*.tar.zst' | while read -r tarfile; do
    base="${tarfile%.tar.zst}"
    # Only back up if .done exists and there is NO .inprogress or _filelist.txt
    if [ -f "${base}.done" ] && [ ! -f "${base}.inprogress" ] && [ ! -f "${base}_filelist.txt" ]; then
        # Optional: also check that the file is not open by any process (extra safety)
        if ! lsof "$tarfile" >/dev/null 2>&1; then
            echo "Backing up: $tarfile"
            "$IDRIVE_CLI" --backup "$tarfile" --silent
            # Optionally touch another file to confirm backup if needed
        else
            echo "Skipping (open by a process): $tarfile"
        fi
    else
        echo "Skipping (not finished): $tarfile"
    fi
done
