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

: << 'MEGA_CC'

# Path to MEGA-CC .deb
DEB="1_CONFIG_FILES/mega-cc_12.0.14-1_amd64_beta.deb"

# Inspect dependencies and install MEGA-CC
echo "📦 Inspecting dependencies for $DEB..."
dpkg-deb -f "$DEB" Depends
sudo dpkg -i "$DEB"

echo "✅ Installation complete. Run: megacc --version"

megacc --version

# Conda Install 

MEGA_CC
