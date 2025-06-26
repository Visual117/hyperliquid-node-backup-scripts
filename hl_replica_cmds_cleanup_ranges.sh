#!/bin/bash

ARCHIVE_DIR="/data/hyperliquid-archives"
REPLICA_CMDS_BASE="/var/lib/hyperliquid/data/replica_cmds"
DRY_RUN=true   # Set to false to actually delete

# 1. Get all archive ranges
find "$ARCHIVE_DIR" -maxdepth 1 -name 'group_*_*.tar.zst' | while read -r f; do
    base=$(basename "$f")
    # Parse block range
    start=$(echo "$base" | grep -oP 'group_\K[0-9]+')
    end=$(echo "$base" | grep -oP '_(\d+)\.tar\.zst' | tr -d '_.' | grep -o '[0-9]\+')
    if [[ -n "$start" && -n "$end" ]]; then
        # For each replica_cmds block folder, check if in range
        find "$REPLICA_CMDS_BASE" -type d -regextype posix-extended -regex '.*/[0-9]{9}$' | while read -r blockfolder; do
            blocknum=$(basename "$blockfolder")
            # Check if blocknum is in this range
            if [[ "$blocknum" -ge "$start" && "$blocknum" -le "$end" ]]; then
                if [ "$DRY_RUN" = true ]; then
                    echo "[DRY RUN] Would delete: $blockfolder"
                else
                    echo "[DELETE] $blockfolder"
                    rm -rf "$blockfolder"
                fi
            fi
        done
    fi
done
