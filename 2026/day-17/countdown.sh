#!/bin/bash
# Count down from a number to 0
read -p "Enter a number to count down from: " n

while [ "$n" -ge 0 ]; do
    echo "$n"
    n=$((n - 1))
done
echo "Done!"
