#!/bin/bash
# Builds a throw-away "project" with files that should NOT end up in an image.
# Run it OUTSIDE your git repo (the fake .git folder would confuse git).
# Usage: ./setup-demo.sh /tmp/dockerignore-project
set -euo pipefail
P="${1:?usage: setup-demo.sh <target-dir>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
rm -rf "$P" && mkdir -p "$P/node_modules/left-pad" "$P/.git"
echo 'console.log("app running")'          > "$P/app.js"
echo '{"name":"demo","version":"1.0.0"}'   > "$P/package.json"
echo 'module.exports = s => s'             > "$P/node_modules/left-pad/index.js"
echo 'ref: refs/heads/main'                > "$P/.git/HEAD"
echo '# demo project'                      > "$P/README.md"
echo '# private notes'                     > "$P/notes.md"
echo 'DB_PASSWORD=super-secret'            > "$P/.env"
cp "$HERE/Dockerfile" "$P/Dockerfile"
echo "demo project created in $P"
