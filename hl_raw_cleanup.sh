#!/bin/bash

REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"
ARCHIVE_DIR="/data/hyperliquid-archives"
DRY_RUN=true   # Set to false to actually delete!

# Find all tarballs that have been offloaded (replace this with the correct logic if needed)
# For now, scan all .tar.zst files in the archive directory:
find "$ARCHIVE_DIR" -name "group_*.tar.zst" | while read -r TARFILE; do
    BASENAME=$(basename "$TARFILE")
    # Extract start and end block numbers
    if [[ "$BASENAME" =~ group_([0-9]+)_([0-9]+).tar.zst ]]; then
        START_BLOCK="${BASH_REMATCH[1]}"
        END_BLOCK="${BASH_REMATCH[2]}"
        echo "Processing archive: $BASENAME [$START_BLOCK - $END_BLOCK]"

        # Search for files in all /replica_cmds/*/* folders matching this range
        find "$REPLICA_CMDS_DIR" -type f | while read -r BLOCKFILE; do
            FILENAME=$(basename "$BLOCKFILE")
            # Check if filename is all digits and within range
            if [[ "$FILENAME" =~ ^[0-9]+$ ]] && (( FILENAME >= START_BLOCK && FILENAME <= END_BLOCK )); then
                echo "Would delete: $BLOCKFILE"
                if [ "$DRY_RUN" = false ]; then
                    rm -f "$BLOCKFILE"
                fi
            fi
        done
    fi
done

# Optionally, after deleting files, remove any empty folders
if [ "$DRY_RUN" = false ]; then
    find "$REPLICA_CMDS_DIR" -type d -empty -delete
fi
