#!/bin/bash

RAW_BLOCKS="$HOME/raw_blocks_present.txt"
ARCHIVE_RANGES="$HOME/archived_block_ranges.txt"
REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"

# For each block, see if it’s in an archived range
while read block; do
    while read start end; do
        if (( block >= start && block <= end )); then
            # Find and print the full path(s) of this block file
            find "$REPLICA_CMDS_DIR" -type f -name "$block" -print
            break
        fi
    done < "$ARCHIVE_RANGES"
done < "$RAW_BLOCKS"
