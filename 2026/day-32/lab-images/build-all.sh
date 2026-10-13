#!/bin/bash
# Rebuilds the three lab images used on Day 32/33. Needs: go, docker, and robin/ubuntu-mini:24.04 (Day 29).
set -euo pipefail
cd "$(dirname "$0")"
export CGO_ENABLED=0
(cd db && go build -o mini-db .)
(cd app && go build -o mini-app .)
(cd tools/ping-src && go build -o ../ping .)
bash ../../day-31/my-first-image/make-curl-bundle.sh >/dev/null
rm -rf tools/curl-bundle && cp -r ../../day-31/my-first-image/curl-bundle tools/curl-bundle
docker build -q -t robin/mini-db:1.0 db
docker build -q -t robin/mini-app:1.0 app
docker build -q -t robin/ubuntu-tools:1.0 tools
