#!/bin/bash

set -e

# MINING_PUBKEY to be used in the nockchain command
MINING_PUBKEY="2cLQ54ec6Caq9C4mTZoSk2Kv4XjJ3vzhyDehgdvEQue6dXZPp9jAa2ZqsaJciB3ZZXomoCjGp53GiyVJNSx2KDn8ehmNGdWcqBsfosDCsAQLDSBW8KgaDDHL4ojiFMSMtHbc"

# Installation directory
INSTALL_DIR="$HOME/nockbin"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for user confirmation
confirm() {
    read -p "$1 [Y/n] " response
    case "$response" in
        [nN][oO]|[nN]) 
            return 1
            ;;
        *)
            return 0
            ;;
    esac
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

    # Install screen using Homebrew on macOS
    if [[ "$OS" == "macos" ]]; then
        if ! command_exists brew; then
            echo "Homebrew is required but was not found."
            if confirm "Would you like to install Homebrew?"; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                echo "Homebrew installation skipped. Cannot continue without Homebrew."
                exit 1
            fi
        fi
        
        if ! command_exists screen; then
            if confirm "Screen is required but not installed. Would you like to install screen?"; then
                echo "Installing screen using Homebrew..."
                brew install screen
            else
                echo "Screen installation skipped. Cannot run nockchain in background without screen."
            fi
        else
            echo "screen is already installed."
        fi
    fi

    # Check if download tools are available
    if ! command_exists curl && ! command_exists wget; then
        echo "Either curl or wget is required but neither was found. Please install one of them and try again."
        exit 1
    fi

    # Check if unzip is installed
    if ! command_exists unzip; then
        echo "unzip is required but was not found."
        if confirm "Would you like to install unzip?"; then
            if [[ "$OS" == "macos" ]]; then
                brew install unzip
            elif [[ "$OS" == "linux-gnu"* ]]; then
                if command_exists apt-get; then
                    sudo apt-get install -y unzip
                elif command_exists yum; then
                    sudo yum install -y unzip
                else
                    echo "Cannot automatically install unzip. Please install it manually and try again."
                    exit 1
                fi
            fi
        else
            echo "Unzip installation skipped. Cannot continue without unzip."
            exit 1
        fi
    fi

    # Confirm installation
    if ! confirm "Ready to install nockchain to $INSTALL_DIR. Continue?"; then
        echo "Installation aborted by user."
        exit 0
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
    
    # Start nockchain in a screen session
    if command_exists screen; then
        if confirm "Would you like to start nockchain miner in a screen session?"; then
            echo "Starting nockchain miner in a screen session..."
            
            # Create the screen session, run commands, and detach
            screen -dmS nock bash -c "cd $INSTALL_DIR && mkdir -p miner-node && cd miner-node && rm -rf nockchain.sock && ./nockchain --fakenet --genesis-watcher --npc-socket nockchain.sock --mining-pubkey $MINING_PUBKEY --bind /ip4/0.0.0.0/udp/3006/quic-v1 --peer /ip4/127.0.0.1/udp/3005/quic-v1 --new-peer-id --no-default-peers; exec bash"
            
            echo "Nockchain miner is now running in a screen session named 'nock'"
            echo "To attach to the session, run: screen -r nock"
            echo "To detach from the session, press: Ctrl+A, then D"
        else
            echo "Nockchain miner not started."
        fi
    else
        echo "screen is not installed. Cannot start nockchain in the background."
        echo "To start nockchain manually, run:"
        echo "cd $INSTALL_DIR && mkdir -p miner-node && cd miner-node && rm -rf nockchain.sock && ./nockchain --fakenet --genesis-watcher --npc-socket nockchain.sock --mining-pubkey $MINING_PUBKEY --bind /ip4/0.0.0.0/udp/3006/quic-v1 --peer /ip4/127.0.0.1/udp/3005/quic-v1 --new-peer-id --no-default-peers"
    fi
    
    echo ""
    echo "Note: Please update the MINING_PUBKEY in this script or replace it in the command above with your actual mining public key."
}

# Run the main function
main 