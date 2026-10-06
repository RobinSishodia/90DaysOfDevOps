#!/bin/bash
# Is the number positive, negative or zero?
read -p "Enter a number: " num

if [ "$num" -gt 0 ]; then
    echo "$num is positive"
elif [ "$num" -lt 0 ]; then
    echo "$num is negative"
else
    echo "The number is zero"
fi
