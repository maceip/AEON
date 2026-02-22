#!/bin/bash
# scripts/setup_ubuntu.sh
# Complete setup for AEON on a vanilla Ubuntu (22.04+)
set -euo pipefail

echo "=== AEON: Total System Setup ==="

# 1. Install System Dependencies
sudo apt-get update
sudo apt-get install -y 
    build-essential cmake git python3 curl wget 
    libxml2-dev xz-utils libssl-dev pkg-config 
    docker.io openssl

# 2. Configure Docker (Required for tools/harness.sh)
sudo usermod -aG docker "$USER"
echo "NOTICE: You may need to log out and back in for Docker group changes to take effect."

# 3. Install Node.js 23 (Official NodeSource)
curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash -
sudo apt-get install -y nodejs

# 4. Install Rust Toolchain (for aot/aot-jit)
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# shellcheck disable=SC1091
    source "$HOME/.cargo/env"
fi
rustup target add wasm32-unknown-unknown

# 5. Install Go (for Network Proxy)
GO_VER="1.23.0"
if ! command -v go &> /dev/null; then
    wget -q https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go${GO_VER}.linux-amd64.tar.gz
    rm go${GO_VER}.linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

# 6. Project Setup & NPM Install
npm install

# 7. FIX: Sync the overlay script (Fixes the mergeTars error we found)
echo "Fixing overlay.js sync..."
cp friscy-bundle/overlay.js public/friscy-bundle/overlay.js

# 8. BUILD EVERYTHING
echo "Starting builds..."

# A. Build Emulator Runtime (C++ -> Wasm via Docker)
# This creates runtime/build/friscy.js and friscy.wasm
./tools/harness.sh

# B. Build Rust JIT (Rust -> Wasm)
cd aot-jit
cargo build --release --target wasm32-unknown-unknown
cd ..

# C. Sync Artifacts for Web App
mkdir -p public/friscy-bundle
cp runtime/build/friscy.js public/friscy-bundle/
cp runtime/build/friscy.wasm public/friscy-bundle/
# Move to the correct public path used in App.tsx
cp public/friscy-bundle/friscy.wasm public/friscy-bundle/friscy.wasm
cp public/friscy-bundle/rootfs.tar public/friscy-bundle/rootfs.tar

# D. Create a basic rootfs (if Docker is running)
if sudo docker ps &> /dev/null; then
    echo "Creating Alpine rootfs..."
    ./tools/container_to_riscv.sh alpine:latest ./output || true
    if [ -f "output/rootfs.tar" ]; then
        cp output/rootfs.tar public/friscy-bundle/
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo "To start the development server:"
echo "npm run dev"
