#!/bin/bash
# Install packages only if they are missing (Debian/Ubuntu)

# Must run as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: please run as root (sudo $0)"
    exit 1
fi

packages=(nginx curl wget)

for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "[OK]       $pkg is already installed"
    else
        echo "[MISSING]  $pkg - installing..."
        if timeout 120 apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
            echo "[INSTALLED] $pkg"
        else
            echo "[FAILED]   $pkg could not be installed (check network / apt sources)"
        fi
    fi
done
