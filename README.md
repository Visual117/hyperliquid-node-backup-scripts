# Hyperliquid Node Backup & Prune Automation (July 2025)

This repository contains all scripts and instructions needed to automate, compress, offload, and prune Hyperliquid node data.

## Active Automation Scripts

- **hl_daily_backup_and_compress.sh**  
  Compresses, offloads, and deletes yesterday's raw `node_order_statuses` and `periodic_abci_states` folders.  
  - Runs nightly at 12:30 AM Eastern via cron.
  - After compressing (`zstd -19 --rm`), invokes the backup/upload scripts for iDrive/S3.
  - Original raw folders are deleted after compression to minimize disk use.

- **hl_prune_zst_archives.sh**  
  Prunes local `.zst` archives, keeping only the 2 most recent per folder for quick local restore if needed.  
  - Runs daily at 2:30 AM Eastern via cron.

## Example crontab


# Hyperliquid Node Backup & Cleanup Automation

Automated scripts for **Hyperliquid node operators** to manage, compress, back up, and clean up large data directories. This suite is designed to prevent disk bloat, automate offsite backups (via IDrive), and keep your node healthy with minimal manual intervention.

IDrive currently offers 10TB of cloud storage for $4.98/yearly!

## 📦 What’s Included

- **Batch compression** of raw node block data into `.tar.zst` archives.
- **Automated backup** of completed archives to IDrive cloud storage.
- **Cleanup** of local archives _after_ confirmed backup.
- **Cleanup** of raw replica data, so you never re-compress already archived blocks.
- **Master cron script** to orchestrate everything in the correct order and avoid overlap.

---

## 🚀 Usage Overview

**Clone the repo and copy the scripts to `/usr/local/bin/` (or your preferred dir).**  
Make sure all scripts are executable:  
```bash
chmod +x /usr/local/bin/hl_*.sh

```

---

## Credits

**Developed by [Visual117](https://github.com/Visual117) for managing and scaling Hyperliquid node infrastructure.**

---
