#!/bin/bash
# Demonstrates each part of "set -euo pipefail".
# Each demo runs in its own child bash so one failure doesn't stop the others.

echo "=== 1) set -u : using an undefined variable ==="
bash -c 'echo "without -u -> [$UNDEFINED_VAR] (empty, no error)"'
bash -c 'set -u; echo "with -u -> [$UNDEFINED_VAR]"'
echo "exit code: $?"

echo
echo "=== 2) set -e : a command fails ==="
bash -c 'false; echo "without -e -> script keeps going after failure"'
bash -c 'set -e; false; echo "with -e -> you will NOT see this"'
echo "exit code: $?"

echo
echo "=== 3) set -o pipefail : a command fails inside a pipe ==="
bash -c 'cat /no/such/file 2>/dev/null | wc -l; echo "without pipefail -> pipe exit code: $?"'
bash -c 'set -o pipefail; cat /no/such/file 2>/dev/null | wc -l; echo "with pipefail -> pipe exit code: $?"'

echo
echo "=== All together ==="
set -euo pipefail
echo "set -euo pipefail is now ON for the rest of this script"
