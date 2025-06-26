#!/bin/bash

LOCKFILE="/tmp/$(basename "$0").lock"
exec 200>"$LOCKFILE"
flock -n 200 || { echo "Script is already running. Exiting."; exit 1; }

ARCHIVE_DIR="/data/hyperliquid-archives"

for donefile in "$ARCHIVE_DIR"/*.done; do
    [ -e "$donefile" ] || continue  # skip if no .done files
    groupbase="${donefile%.done}"
    if [ -f "${groupbase}.tar.zst" ]; then
        echo "Deleting archive: ${groupbase}.tar.zst and done file: $donefile"
        rm -f "${groupbase}.tar.zst"
    fi
    # Delete the .done file regardless
    rm -f "$donefile"
done
