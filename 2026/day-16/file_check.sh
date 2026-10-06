#!/bin/bash
# Does the file exist?
read -p "Enter a file name: " file

if [ -f "$file" ]; then
    echo "File '$file' exists"
else
    echo "File '$file' does not exist"
fi
