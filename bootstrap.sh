#!/bin/sh
set -eux

# --- Install base dependencies for Nix and Home Manager ---
sudo apt-get update
sudo apt-get install -y git sudo passwd curl

# --- Grant passwordless sudo to the current user ---
CURRENT_USER="$(id -un)"
echo "${CURRENT_USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${CURRENT_USER}" >/dev/null
sudo chmod 0440 "/etc/sudoers.d/${CURRENT_USER}"

# --- Install Nix if not already installed ---
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh
  sh /tmp/nix-install.sh --no-daemon
fi

# --- Source Nix profile if available ---
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.fish" ]; then
  # fallback for fish users
  . "$HOME/.nix-profile/etc/profile.d/nix.fish"
fi

# --- Add or update nixpkgs channel to 25.05 ---
if nix-channel --list | grep -q '^nixpkgs '; then
  nix-channel --remove nixpkgs
fi
nix-channel --add https://nixos.org/channels/nixpkgs-25.05-darwin nixpkgs
nix-channel --update

# --- Add or update Home Manager channel to 25.05 ---
if nix-channel --list | grep -q '^home-manager '; then
  nix-channel --remove home-manager
fi
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update

# --- Install Home Manager if not already installed ---
if ! command -v home-manager >/dev/null 2>&1; then
  nix-shell '<home-manager>' -A install
fi

# --- Run home-manager switch to apply configuration ---
if command -v home-manager >/dev/null 2>&1; then
  home-manager switch
else
  echo "home-manager not found after installation, aborting."
  exit 1
fi

# --- Ensure ~/nix-windows exists and is up-to-date ---
REPO_URL="https://github.com/WillyWinkel/nix-windows.git"
TARGET_DIR="$HOME/nix-windows"
if [ ! -d "$TARGET_DIR" ]; then
  git clone "$REPO_URL" "$TARGET_DIR"
else
  git -C "$TARGET_DIR" pull
fi

cd "$TARGET_DIR"

# --- Prepare fish as default shell (do not remove this block!) ---
# Use nix to get the correct fish path
FISH_PATH="$(nix eval --raw nixpkgs.fish)/bin/fish"
if [ -x "$FISH_PATH" ] && ! grep -qx "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi
CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
if [ -x "$FISH_PATH" ] && [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
  chsh -s "$FISH_PATH"
fi

echo "Bootstrap complete. You can now run 'home-manager switch'."
