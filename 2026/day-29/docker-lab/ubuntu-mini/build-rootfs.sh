#!/bin/bash
# Build a tiny Ubuntu-based root filesystem from the host's own binaries + their libraries,
# then import it as a Docker image (no registry needed).
set -euo pipefail
ROOT=/root/docker-lab/ubuntu-mini/rootfs
mkdir -p "$ROOT"/{bin,etc,root,tmp,proc,sys,dev,home}
chmod 1777 "$ROOT/tmp"

BINS="bash sh ls cat echo pwd hostname uname mkdir touch rm head tail id whoami env ps sleep grep date df wc"
for b in $BINS; do
    src=$(type -P "$b")
    cp -L "$src" "$ROOT/bin/"
    # copy every shared library the binary needs, keeping the same path
    for lib in $(ldd "$src" 2>/dev/null | grep -oE '/[^ ]+'); do
        mkdir -p "$ROOT$(dirname "$lib")"
        cp -Ln "$lib" "$ROOT$lib" 2>/dev/null || true
    done
done
# ps needs these to map uids/names
cp /etc/os-release "$ROOT/etc/os-release"
printf 'root:x:0:0:root:/root:/bin/bash\n' > "$ROOT/etc/passwd"
printf 'root:x:0:\n' > "$ROOT/etc/group"
du -sh "$ROOT"
