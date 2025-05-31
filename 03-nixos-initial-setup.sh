#!/usr/bin/env bash
set -euo pipefail

trap 'echo "An error occurred. Press enter to exit."; read -r' ERR

echo -e "\n=== NixOS WSL Initial Setup ===\n"

# Update NixOS channels
echo "Updating NixOS channels..."
if ! sudo nix-channel --update; then
  echo "ERROR: Failed to update NixOS channels."
  read -r
  exit 1
fi

# Rebuild NixOS configuration
echo "Rebuilding NixOS configuration..."
if ! sudo nixos-rebuild switch; then
  echo "ERROR: Failed to rebuild NixOS configuration."
  read -r
  exit 1
fi

# Set NixOS as default WSL distribution
echo "Setting NixOS as default WSL distribution..."
if ! wsl.exe -s NixOS; then
  echo "ERROR: Failed to set NixOS as default WSL distribution."
  read -r
  exit 1
fi

# Check for nix-shell
if ! command -v nix-shell >/dev/null 2>&1; then
  echo "ERROR: nix-shell not found. Please ensure Nix is installed."
  read -r
  exit 1
fi

# Enter dev environment and install required tools
echo "Entering temporary dev environment and installing required tools..."
nix-shell -p git -p vim -p just -p tmux -p nixos-rebuild --run '
  set -e
  echo "Configuring SSH (manual step may be required for keys)..."
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  touch ~/.ssh/config
  chmod 600 ~/.ssh/config

  echo "Cloning configuration repository if not present..."
  if [ ! -d ~/Git/toolbox ]; then
    mkdir -p ~/Git
    # Use HTTPS if SSH keys are not set up
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
      git clone git@github.com:GregHilston/toolbox.git ~/Git/toolbox
    else
      git clone https://github.com/GregHilston/toolbox.git ~/Git/toolbox
    fi
  fi

  echo "Linking configuration..."
  sudo ln -sf "$HOME/Git/toolbox/nixos/hosts/pcs/foundation/default.nix" /etc/nixos/configuration.nix
'

echo "NixOS WSL setup complete. You may need to configure SSH keys manually."
echo "Press enter to exit."
read -r
