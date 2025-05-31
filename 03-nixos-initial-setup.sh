#!/usr/bin/env bash
set -e

# Update NixOS channels
sudo nix-channel --update

# Set NixOS as default WSL distribution
wsl.exe -s NixOS

# Create a temporary dev environment and install required tools
nix-shell -p git -p vim -p just -p tmux -p nixos-rebuild --run '
  # Configure SSH (manual step may be required for keys)
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  touch ~/.ssh/config
  chmod 600 ~/.ssh/config

  # Clone configuration repository
  if [ ! -d ~/Git/toolbox ]; then
    mkdir -p ~/Git
    git clone git@github.com:GregHilston/toolbox.git ~/Git/toolbox
  fi

  # Link configuration
  sudo ln -sf "$HOME/Git/toolbox/nixos/hosts/pcs/foundation/default.nix" /etc/nixos/configuration.nix
'
echo "NixOS WSL setup complete. You may need to configure SSH keys manually."
