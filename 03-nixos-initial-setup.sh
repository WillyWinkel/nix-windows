#!/usr/bin/env bash
set -u

trap 'echo "An error occurred. Press enter to exit."; read' ERR

echo -e "\n=== NixOS WSL Initial Setup ===\n"

echo "Updating NixOS channels..."
if ! sudo nix-channel --update; then
  echo "ERROR: Failed to update NixOS channels."
  read
  exit 1
fi

echo "Setting NixOS as default WSL distribution..."
if ! wsl.exe -s NixOS; then
  echo "ERROR: Failed to set NixOS as default WSL distribution."
  read
  exit 1
fi

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
    git clone git@github.com:GregHilston/toolbox.git ~/Git/toolbox
  fi

  echo "Linking configuration..."
  sudo ln -sf "$HOME/Git/toolbox/nixos/hosts/pcs/foundation/default.nix" /etc/nixos/configuration.nix
'

echo "NixOS WSL setup complete. You may need to configure SSH keys manually."
read -p "Press enter to exit."
