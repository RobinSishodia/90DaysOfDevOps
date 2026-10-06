# Day 19 – Shell Scripting Project: Log Rotation, Backup & Crontab

> Practice VM: Ubuntu 24.04 cloud microVM. Scripts: `log_rotate.sh`, `backup.sh`, `maintenance.sh` (all in this folder). I created test logs with fake ages using `touch -d '10 days ago'`.

## Task 1: `log_rotate.sh`
```bash
#!/bin/bash
set -euo pipefail
LOG_DIR="${1:-}"

if [ -z "$LOG_DIR" ]; then echo "Usage: $0 <log_directory>"; exit 1; fi
if [ ! -d "$LOG_DIR" ]; then echo "ERROR: directory '$LOG_DIR' does not exist"; exit 1; fi

compressed=0; deleted=0

while IFS= read -r -d '' file; do
    gzip "$file"; echo "Compressed: $file"; compressed=$((compressed + 1))
done < <(find "$LOG_DIR" -type f -name "*.log" -mtime +7 -print0)

while IFS= read -r -d '' file; do
    rm -f -- "$file"; echo "Deleted:    $file"; deleted=$((deleted + 1))
done < <(find "$LOG_DIR" -type f -name "*.gz" -mtime +30 -print0)

echo "Summary: $compressed file(s) compressed, $deleted file(s) deleted in $LOG_DIR"
```
**Before:**
```
-rw-r--r-- 1 root root 36 2026-08-27 ancient.log.gz     ← 40 days old
-rw-r--r-- 1 root root  0 2026-09-26 app-old.log        ← 10 days old
-rw-r--r-- 1 root root  0 2026-10-04 app-recent.log     ← 2 days old
-rw-r--r-- 1 root root  0 2026-10-06 app-today.log
-rw-r--r-- 1 root root  0 2026-09-27 error-old.log      ← 9 days old
```
**Run:**
```
$ ./log_rotate.sh
Usage: ./log_rotate.sh <log_directory>
$ ./log_rotate.sh /no/such/dir; echo "exit code: $?"
ERROR: directory '/no/such/dir' does not exist
exit code: 1
$ ./log_rotate.sh /var/log/myapp
Compressed: /var/log/myapp/app-old.log
Compressed: /var/log/myapp/error-old.log
Deleted:    /var/log/myapp/ancient.log.gz
Summary: 2 file(s) compressed, 1 file(s) deleted in /var/log/myapp
```
**After:**
```
-rw-r--r-- 1 root root 32 2026-09-26 app-old.log.gz
-rw-r--r-- 1 root root  0 2026-10-04 app-recent.log     ← untouched (< 7 days)
-rw-r--r-- 1 root root  0 2026-10-06 app-today.log
-rw-r--r-- 1 root root 34 2026-09-27 error-old.log.gz
```
`find -print0` + `read -d ''` handles filenames with spaces safely.

## Task 2: `backup.sh`
```bash
#!/bin/bash
set -euo pipefail
SRC="${1:-}"; DEST="${2:-}"

if [ -z "$SRC" ] || [ -z "$DEST" ]; then echo "Usage: $0 <source_dir> <backup_dir>"; exit 1; fi
if [ ! -d "$SRC" ]; then echo "ERROR: source directory '$SRC' does not exist"; exit 1; fi

mkdir -p "$DEST"
ARCHIVE="$DEST/backup-$(date +%F).tar.gz"
tar -czf "$ARCHIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")"

if tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
    echo "Backup created: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
else
    echo "ERROR: backup archive is corrupted"; exit 1
fi

old=$(find "$DEST" -name "backup-*.tar.gz" -mtime +14 -print -delete | wc -l)
echo "Old backups removed: $old"
```
```
$ ls /backups
backup-2026-09-16.tar.gz                      ← fake 20-day-old backup
$ ./backup.sh /srv/data /backups
Backup created: /backups/backup-2026-10-06.tar.gz (4.0K)
Old backups removed: 1
$ tar -tzf /backups/backup-2026-10-06.tar.gz
data/
data/app.conf
data/db.sql
$ ./backup.sh /no/such/dir /backups; echo "exit code: $?"
ERROR: source directory '/no/such/dir' does not exist
exit code: 1
```
**Verifying the archive** (`tar -tzf`) matters: a backup you've never test-read isn't a backup.

## Task 3: Crontab
```
$ crontab -l
crontab: command not found
```
My practice VM has no cron installed, so the entries below are written out but not installed.
```
┌───────── minute (0-59)
│ ┌─────── hour (0-23)
│ │ ┌───── day of month (1-31)
│ │ │ ┌─── month (1-12)
│ │ │ │ ┌─ day of week (0-7, Sun = 0 or 7)
│ │ │ │ │
* * * * *  command
```
```cron
# Log rotation every day at 2 AM
0 2 * * *   /opt/scripts/log_rotate.sh /var/log/myapp >> /var/log/log_rotate.log 2>&1

# Backup every Sunday at 3 AM
0 3 * * 0   /opt/scripts/backup.sh /srv/data /backups >> /var/log/backup.log 2>&1

# Health check every 5 minutes
*/5 * * * * /opt/scripts/health_check.sh >> /var/log/health.log 2>&1

# Full maintenance every day at 1 AM
0 1 * * *   /opt/scripts/maintenance.sh
```
Cron runs with a **minimal environment** (`PATH=/usr/bin:/bin`, `/bin/sh`), so use absolute paths and a proper shebang, and redirect output to a log or you'll never see the errors.

## Task 4: `maintenance.sh`
```bash
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${MAINT_LOG:-/var/log/maintenance.log}"
APP_LOG_DIR="${APP_LOG_DIR:-/var/log/myapp}"
DATA_DIR="${DATA_DIR:-/srv/data}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

log "===== Maintenance started ====="
log "Step 1: log rotation for $APP_LOG_DIR"
"$SCRIPT_DIR/log_rotate.sh" "$APP_LOG_DIR" 2>&1 | while read -r line; do log "  $line"; done
log "Step 2: backup of $DATA_DIR to $BACKUP_DIR"
"$SCRIPT_DIR/backup.sh" "$DATA_DIR" "$BACKUP_DIR" 2>&1 | while read -r line; do log "  $line"; done
log "===== Maintenance finished ====="
```
```
$ ./maintenance.sh
[2026-10-06 18:50:58] ===== Maintenance started =====
[2026-10-06 18:50:58] Step 1: log rotation for /var/log/myapp
[2026-10-06 18:50:58]   Compressed: /var/log/myapp/worker.log
[2026-10-06 18:50:58]   Summary: 1 file(s) compressed, 0 file(s) deleted in /var/log/myapp
[2026-10-06 18:50:58] Step 2: backup of /srv/data to /backups
[2026-10-06 18:50:58]   Backup created: /backups/backup-2026-10-06.tar.gz (4.0K)
[2026-10-06 18:50:58]   Old backups removed: 0
[2026-10-06 18:50:58] ===== Maintenance finished =====

$ tail -n 4 /var/log/maintenance.log
[2026-10-06 18:50:58] Step 2: backup of /srv/data to /backups
[2026-10-06 18:50:58]   Backup created: /backups/backup-2026-10-06.tar.gz (4.0K)
[2026-10-06 18:50:58]   Old backups removed: 0
[2026-10-06 18:50:58] ===== Maintenance finished =====
```
**Cron entry:** `0 1 * * * /opt/scripts/maintenance.sh`

## Key learnings
1. **`find -mtime +N` is the core of retention policies.** Combined with `gzip` or `-delete`, it's a mini logrotate.
2. **Small scripts + one orchestrator** (`maintenance.sh`) are easier to test and reuse than one giant script.
3. **Cron jobs need absolute paths, logging and timestamps.** Otherwise a 1 AM failure is invisible.
