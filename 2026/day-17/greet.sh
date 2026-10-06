#!/bin/bash
# Greet the name passed as the first argument
if [ -z "$1" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

echo "Hello, $1!"
