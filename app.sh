#!/bin/bash

set -e

# MINING_PUBKEY to be used in the nockchain command
MINING_PUBKEY="your-mining-pubkey-here"

# Installation directory
INSTALL_DIR="$HOME/Projects/nockchain"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Detect architecture
detect_arch() {
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        echo "x86_64"
    elif [[ "$arch" == "arm64" ]] || [[ "$arch" == "aarch64" ]]; then
        echo "arm64"
    else
        echo "Unsupported architecture: $arch"
        exit 1
    fi
}

# Main function
main() {
    echo "Nockchain Installation Script"
    echo "============================"

    # Detect OS and architecture
    OS=$(detect_os)
    ARCH=$(detect_arch)
    echo "Detected: $OS on $ARCH"

    # Check if download tools are available
    if ! command_exists curl && ! command_exists wget; then
        echo "Either curl or wget is required but neither was found. Please install one of them and try again."
        exit 1
    fi

    # Check if unzip is installed
    if ! command_exists unzip; then
        echo "unzip is required but was not found. Please install it and try again."
        exit 1
    fi

    # Create installation directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Creating installation directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi

    # Set download URL based on OS and architecture
    DOWNLOAD_URL="https://github.com/sarkrui/nockchain-auto/releases/latest/download/nockchain-all-$OS-$ARCH.zip"
    TEMP_ZIP="$INSTALL_DIR/nockchain-all-$OS-$ARCH.zip"

    echo "Downloading nockchain binaries from: $DOWNLOAD_URL"
    
    # Download the zip file
    if command_exists curl; then
        curl -L "$DOWNLOAD_URL" -o "$TEMP_ZIP"
    else
        wget "$DOWNLOAD_URL" -O "$TEMP_ZIP"
    fi

    if [ ! -f "$TEMP_ZIP" ]; then
        echo "Failed to download nockchain binaries"
        exit 1
    fi

    # Extract the zip file
    echo "Extracting binaries to $INSTALL_DIR"
    unzip -o "$TEMP_ZIP" -d "$INSTALL_DIR"

    # Make binaries executable
    echo "Making binaries executable"
    chmod +x "$INSTALL_DIR/nockchain-wallet" "$INSTALL_DIR/equix-latency" "$INSTALL_DIR/hoonc" "$INSTALL_DIR/nockchain" "$INSTALL_DIR/nockchain-bitcoin-sync"

    # Clean up
    echo "Cleaning up"
    rm "$TEMP_ZIP"

    echo "Installation complete!"
    echo ""
    echo "Nockchain binaries have been installed to: $INSTALL_DIR"
    echo ""
    echo "To start nockchain, run:"
    echo "$INSTALL_DIR/nockchain --mainnet --genesis-watcher --npc-socket nockchain.sock --mining-pubkey $MINING_PUBKEY --bind /ip4/0.0.0.0/udp/3006/quic-v1 --peer /ip4/127.0.0.1/udp/3005/quic-v1 --new-peer-id --no-default-peers"
    echo ""
    echo "Note: Please update the MINING_PUBKEY in this script or replace it in the command above with your actual mining public key."
}

# Run the main function
main 