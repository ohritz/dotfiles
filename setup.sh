#!/usr/bin/env bash

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

main() {
    echo "Starting system setup..."

    # Update package list and install essential packages
    echo "Installing system packages..."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        gcc \
        icu-libs \
        curl \
        wget \
        procps \
        file \
        git \
        python3 \
        python3-pip \
        pipx \
        zsh

    # Install homebrew
    echo "Installing Homebrew..."
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo >> /home/ohritz/.bashrc
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/ohritz/.bashrc
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    # Install keeper commander via pipx
    echo "Installing Keeper Commander..."
    pipx install keepercommander
    pipx ensurepath

    # Add pipx bin directory to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/ohritz/.bashrc

    # Verify keeper is now available
    if ! command -v keeper &> /dev/null; then
        echo "Error: keeper command not found even after adding to PATH"
        echo "Please check your pipx installation"
        exit 1
    fi

    echo "Keeper Commander installed successfully!"
    echo ""
    echo "SETUP INSTRUCTIONS:"
    echo "1. Set correct server: server EU"
    echo "2. Login and set persistent-login to on"
    echo "3. Reference: https://docs.keeper.io/en/keeperpam/commander-cli/commander-installation-setup/logging-in#persistent-login-sessions-stay-logged-in"
    echo "4. Run: My Vault> this-device persistent-login on"
    echo ""
    read -p "Press enter to open Keeper shell..."

    keeper shell

    echo ""
    echo "Now installing and setting up chezmoi..."
    read -p "Press enter to continue with chezmoi setup..."

    # Install chezmoi
    if ! command -v chezmoi &> /dev/null; then
        sh -c "$(curl -fsLS get.chezmoi.io)"
        # Add chezmoi to PATH if installed in local bin
        if [ -f "$HOME/bin/chezmoi" ]; then
            export PATH="$HOME/bin:$PATH"
            echo 'export PATH="$HOME/bin:$PATH"' >> /home/ohritz/.bashrc
        fi
    fi

    # Initialize and apply chezmoi
    chezmoi init https://github.com/ohritz/dotfiles.git
    chezmoi apply

    # Change default shell to zsh
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)

    echo ""
    echo "Setup complete! Please restart your terminal or run 'exec zsh' to start using your new configuration."
}

main "$@"
