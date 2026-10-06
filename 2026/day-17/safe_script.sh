#!/bin/bash
# Stop on the first error, and explain what failed
set -e

DIR=/tmp/devops-test

mkdir -p "$DIR" || { echo "ERROR: cannot create $DIR"; exit 1; }
cd "$DIR"       || { echo "ERROR: cannot cd into $DIR"; exit 1; }
touch notes.txt || { echo "ERROR: cannot create notes.txt"; exit 1; }

echo "Created $DIR/notes.txt"

# This will fail on purpose - set -e would stop the script here,
# but || lets us print a friendly message first
cd /does/not/exist || { echo "ERROR: /does/not/exist is missing - stopping"; exit 1; }

echo "You will never see this line"
