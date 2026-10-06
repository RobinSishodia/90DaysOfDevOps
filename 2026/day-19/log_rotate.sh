#!/bin/bash
# Usage: ./log_rotate.sh <log_directory>
# - gzip .log files older than 7 days
# - delete .gz files older than 30 days
set -euo pipefail

LOG_DIR="${1:-}"

if [ -z "$LOG_DIR" ]; then
    echo "Usage: $0 <log_directory>"
    exit 1
fi

if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: directory '$LOG_DIR' does not exist"
    exit 1
fi

compressed=0
deleted=0

# Compress .log files older than 7 days
while IFS= read -r -d '' file; do
    gzip "$file"
    echo "Compressed: $file"
    compressed=$((compressed + 1))
done < <(find "$LOG_DIR" -type f -name "*.log" -mtime +7 -print0)

# Delete .gz files older than 30 days
while IFS= read -r -d '' file; do
    rm -f -- "$file"
    echo "Deleted:    $file"
    deleted=$((deleted + 1))
done < <(find "$LOG_DIR" -type f -name "*.gz" -mtime +30 -print0)

echo "Summary: $compressed file(s) compressed, $deleted file(s) deleted in $LOG_DIR"
