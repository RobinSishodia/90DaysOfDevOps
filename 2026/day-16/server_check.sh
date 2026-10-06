#!/bin/bash
# Ask before checking a service's status
service="ssh"

read -p "Do you want to check the status of '$service'? (y/n): " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    if command -v systemctl >/dev/null && [ -d /run/systemd/system ]; then
        systemctl status "$service" --no-pager
    else
        # Fallback for machines/containers without systemd
        echo "systemd is not running here - checking the process instead:"
        pgrep -a "${service}d" || echo "$service is not running"
    fi
else
    echo "Skipped."
fi
