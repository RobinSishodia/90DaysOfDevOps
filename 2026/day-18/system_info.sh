#!/bin/bash
# System information report
set -euo pipefail

header() {
    echo
    echo "=============================="
    echo " $1"
    echo "=============================="
}

host_info() {
    header "Host & OS"
    echo "Hostname : $(hostname)"
    echo "OS       : $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    echo "Kernel   : $(uname -r)"
}

uptime_info() {
    header "Uptime"
    uptime -p
}

disk_info() {
    header "Top 5 largest directories in /var"
    du -sh /var/* 2>/dev/null | sort -rh | head -5 || true
}

memory_info() {
    header "Memory"
    free -h
}

cpu_info() {
    header "Top 5 CPU processes"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -6
}

main() {
    echo "System report generated: $(date '+%Y-%m-%d %H:%M:%S')"
    host_info
    uptime_info
    disk_info
    memory_info
    cpu_info
}

main
