# Day 20 – Log Analyzer & Report Generator

> Practice VM: Ubuntu 24.04 cloud microVM. I generated a realistic 191-line `sample_app.log` (INFO/WARNING/ERROR/CRITICAL entries) to test with. After the run it was archived to `archive/sample_app.log`, and the report is `log_report_2026-10-06.txt` (both committed).

## Sample input
```
$ head -n 5 sample_app.log
2026-10-06 09:00:06 [INFO] Health check OK
2026-10-06 09:00:53 [WARNING] Slow query detected (2.3s)
2026-10-06 09:01:46 [INFO] User login successful
2026-10-06 09:02:09 [INFO] User login successful
2026-10-06 09:02:50 [INFO] User login successful
$ wc -l sample_app.log
191 sample_app.log
```

## The script – `log_analyzer.sh`
```bash
#!/bin/bash
set -euo pipefail
LOG_FILE="${1:-}"

# Task 1: input validation
if [ -z "$LOG_FILE" ]; then echo "Usage: $0 <log_file>"; exit 1; fi
if [ ! -f "$LOG_FILE" ]; then echo "ERROR: file '$LOG_FILE' not found"; exit 1; fi

DATE=$(date +%Y-%m-%d)
REPORT="log_report_${DATE}.txt"
TOTAL_LINES=$(wc -l < "$LOG_FILE")

# Task 2: error count
ERROR_COUNT=$(grep -cE "ERROR|Failed" "$LOG_FILE" || true)
echo "Total ERROR/Failed lines: $ERROR_COUNT"

# Task 3: critical events with line numbers
CRITICAL=$(grep -n "CRITICAL" "$LOG_FILE" || true)
echo; echo "--- Critical Events ---"; echo "${CRITICAL:-None}"

# Task 4: top 5 error messages
TOP_ERRORS=$(grep "ERROR" "$LOG_FILE" \
    | sed -E 's/^[0-9-]+ [0-9:]+ \[ERROR\] //' \
    | sort | uniq -c | sort -rn | head -5 || true)
echo; echo "--- Top 5 Error Messages ---"; echo "$TOP_ERRORS"

# Task 5: summary report
{
    echo "========================================"
    echo " Log Analysis Report"
    echo "========================================"
    echo "Date of analysis : $DATE"
    echo "Log file         : $LOG_FILE"
    echo "Total lines      : $TOTAL_LINES"
    echo "Total errors     : $ERROR_COUNT"
    echo; echo "--- Top 5 Error Messages ---"; echo "$TOP_ERRORS"
    echo; echo "--- Critical Events ---"; echo "${CRITICAL:-None}"
} > "$REPORT"
echo; echo "Report saved to: $REPORT"

# Task 6: archive
mkdir -p archive
mv "$LOG_FILE" archive/
echo "Archived: $LOG_FILE -> archive/$(basename "$LOG_FILE")"
```

## Output
```
$ ./log_analyzer.sh
Usage: ./log_analyzer.sh <log_file>

$ ./log_analyzer.sh nothing.log; echo "exit code: $?"
ERROR: file 'nothing.log' not found
exit code: 1

$ ./log_analyzer.sh sample_app.log
Total ERROR/Failed lines: 28

--- Critical Events ---
62:2026-10-06 09:47:21 [CRITICAL] Kernel OOM killer invoked
127:2026-10-06 10:37:48 [CRITICAL] Disk /dev/sda1 is 98% full
174:2026-10-06 11:08:41 [CRITICAL] Service payment-api is DOWN

--- Top 5 Error Messages ---
      9 Database connection timeout
      6 Failed to write to /var/data: Permission denied
      5 Payment API returned 503
      3 Out of memory in worker-3
      2 Invalid JWT token

Report saved to: log_report_2026-10-06.txt
Archived: sample_app.log -> archive/sample_app.log
```
**An interesting detail:** 28 = **26 ERROR lines + 2 INFO lines** that say *"Failed login attempt"*. `grep "Failed"` matches the word anywhere, not just the log level. In a real tool I'd match `\[ERROR\]` exactly and report failed logins separately (they matter for security, not uptime).

## Tools used
| Tool | Used for |
|---|---|
| `grep -c` / `grep -E` | Counting ERROR or Failed lines |
| `grep -n` | Critical lines **with line numbers** |
| `sed -E` | Stripping the timestamp so identical messages group together |
| `sort \| uniq -c \| sort -rn \| head -5` | The classic "top N" pipeline |
| `wc -l`, `date +%Y-%m-%d` | Totals, dated report name |
| `mkdir -p`, `mv` | Archiving the processed log |

## Key learnings
1. **`sort | uniq -c | sort -rn | head`** answers "what's the most common X?" for anything: errors, IPs, URLs, users.
2. **Normalise before you count.** Stripping timestamps with `sed` is what turns 26 unique lines into 5 meaningful error groups.
3. **Be precise with patterns.** A loose `grep "Failed"` mixed security events into the error count.
