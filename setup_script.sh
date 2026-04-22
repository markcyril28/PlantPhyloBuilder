#!/bin/bash
# Install MEGA-CC 12.0.14 and common alignment tools

set -euo pipefail

# Local Install 
# Update and fix broken dependencies
sudo apt-get update && sudo apt-get install -f -y

# Install alignment tools and required runtime dependencies
sudo apt-get install -y \
    muscle clustalw clustalo mafft t-coffee probcons \
    iqtree desktop-file-utils

#sudo apt-get remove --purge mega

# Path to MEGA-CC .deb
DEB="1_CONFIG_FILES/mega-cc_12.0.14-1_amd64_beta.deb"

# Inspect dependencies and install MEGA-CC
echo "Inspecting dependencies for $DEB..."
dpkg-deb -f "$DEB" Depends
sudo dpkg -i "$DEB"

echo "MEGA-CC installation complete."
megacc --version

# ── ModelTest-NG installation ────────────────────────────────────────────────
echo ""
echo "Checking ModelTest-NG..."

if command -v modeltest-ng &>/dev/null; then
    echo "ModelTest-NG already installed: $(modeltest-ng --version 2>&1 | head -1)"
else
    echo "Installing ModelTest-NG..."
    MODELTEST_INSTALLED=false

    # Try conda / mamba first (preferred in bioinformatics environments)
    if command -v mamba &>/dev/null; then
        echo "  Trying mamba..."
        if mamba install -c bioconda -c conda-forge -y modeltest-ng; then
            MODELTEST_INSTALLED=true
        fi
    elif command -v conda &>/dev/null; then
        echo "  Trying conda..."
        if conda install -c bioconda -c conda-forge -y modeltest-ng; then
            MODELTEST_INSTALLED=true
        fi
    fi

    if [[ "$MODELTEST_INSTALLED" == false ]]; then
        # Download static binary from GitHub releases
        MODELTEST_VERSION="0.1.7"
        MODELTEST_TARBALL="modeltest-ng-static-${MODELTEST_VERSION}-linux-x86_64.tar.gz"
        MODELTEST_URL="https://github.com/ddarriba/modeltest/releases/download/v${MODELTEST_VERSION}/${MODELTEST_TARBALL}"
        MODELTEST_EXTRACT="/tmp/modeltest-ng-extract"

        echo "  Downloading ModelTest-NG v${MODELTEST_VERSION} from GitHub..."
        if wget -q --show-progress --timeout=120 "$MODELTEST_URL" -O "/tmp/${MODELTEST_TARBALL}"; then
            mkdir -p "$MODELTEST_EXTRACT"
            tar -xzf "/tmp/${MODELTEST_TARBALL}" -C "$MODELTEST_EXTRACT"
            MODELTEST_BIN=$(find "$MODELTEST_EXTRACT" -name "modeltest-ng" -type f | head -1)
            if [[ -n "$MODELTEST_BIN" ]]; then
                sudo install -m 755 "$MODELTEST_BIN" /usr/local/bin/modeltest-ng
                echo "  Installed to /usr/local/bin/modeltest-ng"
                MODELTEST_INSTALLED=true
            else
                echo "  ERROR: modeltest-ng binary not found in downloaded archive." >&2
            fi
            rm -rf "/tmp/${MODELTEST_TARBALL}" "$MODELTEST_EXTRACT"
        else
            echo "  ERROR: Failed to download ModelTest-NG from GitHub." >&2
        fi
    fi

    if [[ "$MODELTEST_INSTALLED" == false ]]; then
        echo ""
        echo "  ⚠  ModelTest-NG could not be installed automatically." >&2
        echo "  Manual install options:" >&2
        echo "    conda install -c bioconda modeltest-ng" >&2
        echo "    https://github.com/ddarriba/modeltest/releases/tag/v${MODELTEST_VERSION:-0.1.7}" >&2
        echo "  The pipeline will fall back to static MAO files when modeltest-ng is absent."
        exit 1
    fi

    echo "ModelTest-NG installed: $(modeltest-ng --version 2>&1 | head -1)"
fi

echo ""
echo "All tools installed successfully."
echo "  megacc:        $(megacc --version 2>&1 | head -1)"
echo "  modeltest-ng:  $(modeltest-ng --version 2>&1 | head -1)"
