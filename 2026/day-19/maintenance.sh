#!/bin/bash
# Daily maintenance: log rotation + backup, with timestamped logging
# Cron (daily at 1 AM):  0 1 * * * /opt/scripts/maintenance.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${MAINT_LOG:-/var/log/maintenance.log}"
APP_LOG_DIR="${APP_LOG_DIR:-/var/log/myapp}"
DATA_DIR="${DATA_DIR:-/srv/data}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "===== Maintenance started ====="

log "Step 1: log rotation for $APP_LOG_DIR"
"$SCRIPT_DIR/log_rotate.sh" "$APP_LOG_DIR" 2>&1 | while read -r line; do log "  $line"; done

log "Step 2: backup of $DATA_DIR to $BACKUP_DIR"
"$SCRIPT_DIR/backup.sh" "$DATA_DIR" "$BACKUP_DIR" 2>&1 | while read -r line; do log "  $line"; done

log "===== Maintenance finished ====="
