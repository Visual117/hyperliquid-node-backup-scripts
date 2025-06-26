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

Developed by Visual117 for managing and scaling Hyperliquid node infrastructure.
