#!/bin/bash
# Usage: ./backup.sh <source_dir> <backup_dir>
# - creates backup-YYYY-MM-DD.tar.gz
# - verifies the archive
# - deletes backups older than 14 days
set -euo pipefail

SRC="${1:-}"
DEST="${2:-}"

if [ -z "$SRC" ] || [ -z "$DEST" ]; then
    echo "Usage: $0 <source_dir> <backup_dir>"
    exit 1
fi

if [ ! -d "$SRC" ]; then
    echo "ERROR: source directory '$SRC' does not exist"
    exit 1
fi

mkdir -p "$DEST"

ARCHIVE="$DEST/backup-$(date +%F).tar.gz"

tar -czf "$ARCHIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")"

# Verify the archive can be read
if tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
    echo "Backup created: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
else
    echo "ERROR: backup archive is corrupted"
    exit 1
fi

# Remove backups older than 14 days
old=$(find "$DEST" -name "backup-*.tar.gz" -mtime +14 -print -delete | wc -l)
echo "Old backups removed: $old"
