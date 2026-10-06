#!/bin/bash
# Disk and memory check using functions

check_disk() {
    echo "--- Disk usage (/) ---"
    df -h /
}

check_memory() {
    echo "--- Memory ---"
    free -h
}

main() {
    check_disk
    echo
    check_memory
}

main
