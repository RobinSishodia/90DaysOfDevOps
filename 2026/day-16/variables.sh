#!/bin/bash
# Variables: no spaces around "="
NAME="Robin"
ROLE="DevOps Engineer"

echo "Hello, I am $NAME and I am a $ROLE"

# Single vs double quotes
echo 'Single quotes: Hello, I am $NAME'   # printed literally
echo "Double quotes: Hello, I am $NAME"   # variable is expanded
