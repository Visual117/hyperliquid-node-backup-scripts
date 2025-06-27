#!/bin/bash
set -euo pipefail

# 1) Prune order-status folders: keep only the 2 newest
echo "Pruning old order_statuses..."
ls -1d /var/lib/hyperliquid/data/node_order_statuses/hourly/[0-9]* \
  | sort \
  | head -n -2 \
  | xargs -r rm -rf

# 2) Prune ABCI snapshots: keep only the 2 newest
echo "Pruning old ABCI snapshots..."
ls -1d /var/lib/hyperliquid/data/periodic_abci_states/[0-9]* \
  | sort -r \
  | tail -n +3 \
  | xargs -r rm -rf
