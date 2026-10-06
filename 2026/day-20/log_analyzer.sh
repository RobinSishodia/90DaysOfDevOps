#!/bin/bash
# Usage: ./log_analyzer.sh <log_file>
# Analyses a server log and writes log_report_<date>.txt
set -euo pipefail

LOG_FILE="${1:-}"

# ---------- Task 1: input validation ----------
if [ -z "$LOG_FILE" ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi
if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: file '$LOG_FILE' not found"
    exit 1
fi

DATE=$(date +%Y-%m-%d)
REPORT="log_report_${DATE}.txt"
TOTAL_LINES=$(wc -l < "$LOG_FILE")

# ---------- Task 2: error count ----------
ERROR_COUNT=$(grep -cE "ERROR|Failed" "$LOG_FILE" || true)
echo "Total ERROR/Failed lines: $ERROR_COUNT"

# ---------- Task 3: critical events (with line numbers) ----------
CRITICAL=$(grep -n "CRITICAL" "$LOG_FILE" || true)
echo
echo "--- Critical Events ---"
echo "${CRITICAL:-None}"

# ---------- Task 4: top 5 error messages ----------
# Strip "date time [ERROR]" so identical messages group together
TOP_ERRORS=$(grep "ERROR" "$LOG_FILE" \
    | sed -E 's/^[0-9-]+ [0-9:]+ \[ERROR\] //' \
    | sort | uniq -c | sort -rn | head -5 || true)
echo
echo "--- Top 5 Error Messages ---"
echo "$TOP_ERRORS"

# ---------- Task 5: summary report ----------
{
    echo "========================================"
    echo " Log Analysis Report"
    echo "========================================"
    echo "Date of analysis : $DATE"
    echo "Log file         : $LOG_FILE"
    echo "Total lines      : $TOTAL_LINES"
    echo "Total errors     : $ERROR_COUNT"
    echo
    echo "--- Top 5 Error Messages ---"
    echo "$TOP_ERRORS"
    echo
    echo "--- Critical Events ---"
    echo "${CRITICAL:-None}"
} > "$REPORT"

echo
echo "Report saved to: $REPORT"

# ---------- Task 6: archive the processed log ----------
mkdir -p archive
mv "$LOG_FILE" archive/
echo "Archived: $LOG_FILE -> archive/$(basename "$LOG_FILE")"
