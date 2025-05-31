#!/bin/sh
set -eu

export NIX_CONFIG="experimental-features = nix-command"

echo "==> Checking and installing base dependencies..."

MISSING_PKGS=""
for pkg in git sudo passwd curl; do
  if ! command -v "$pkg" >/dev/null 2>&1; then
    MISSING_PKGS="$MISSING_PKGS $pkg"
  fi
done

if [ -n "$MISSING_PKGS" ]; then
  echo "Installing missing packages:$MISSING_PKGS"
  sudo apt-get update
  sudo apt-get install -y $MISSING_PKGS
else
  echo "All base dependencies already installed."
fi

echo "==> Ensuring ~/nix-windows exists and is up-to-date..."
REPO_URL="https://github.com/WillyWinkel/nix-windows.git"
TARGET_DIR="$HOME/nix-windows"
if [ ! -d "$TARGET_DIR" ]; then
  git clone "$REPO_URL" "$TARGET_DIR"
else
  git -C "$TARGET_DIR" pull --ff-only
fi

cd "$TARGET_DIR"

# Source Nix profile early for current shell and ensure .bashrc is set up
BASHRC="$HOME/.bashrc"
NIX_SH_LINE='[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"'
NIX_FISH_LINE='[ -e "$HOME/.nix-profile/etc/profile.d/nix.fish" ] && . "$HOME/.nix-profile/etc/profile.d/nix.fish"'

if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.fish" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.fish"
fi

if ! grep -Fxq "$NIX_SH_LINE" "$BASHRC"; then
  echo "Adding Nix profile sourcing to .bashrc..."
  echo "$NIX_SH_LINE" >> "$BASHRC"
fi
if ! grep -Fxq "$NIX_FISH_LINE" "$BASHRC"; then
  echo "$NIX_FISH_LINE" >> "$BASHRC"
fi

echo "==> Checking if passwordless sudo is already granted for the current user..."
CURRENT_USER="$(id -un)"
SUDOERS_LINE="${CURRENT_USER} ALL=(ALL) NOPASSWD:ALL"

if sudo grep -qF "$SUDOERS_LINE" /etc/sudoers; then
    echo "Passwordless sudo is already granted for $CURRENT_USER."
else
    echo "Passwordless sudo not found for $CURRENT_USER. Granting now..."
    echo "$SUDOERS_LINE" | sudo EDITOR='tee -a' visudo
    if sudo grep -qF "$SUDOERS_LINE" /etc/sudoers; then
        echo "Passwordless sudo successfully granted for $CURRENT_USER."
    else
        echo "Failed to grant passwordless sudo for $CURRENT_USER."
        exit 1
    fi
fi

echo "==> Checking for Nix installation..."
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh
  sh /tmp/nix-install.sh --no-daemon
else
  echo "Nix already installed."
fi

echo "==> Configuring nixpkgs channel..."
if nix-channel --list | grep -q '^nixpkgs '; then
  nix-channel --remove nixpkgs
fi
nix-channel --add https://nixos.org/channels/nixpkgs-25.05-darwin nixpkgs
nix-channel --update

echo "==> Configuring Home Manager channel..."
if nix-channel --list | grep -q '^home-manager '; then
  nix-channel --remove home-manager
fi
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update

echo "==> Checking for Home Manager installation..."
if ! command -v home-manager >/dev/null 2>&1; then
  echo "Installing Home Manager..."
  nix-shell '<home-manager>' -A install
else
  echo "Home Manager already installed."
fi

echo "==> Running home-manager switch to apply configuration..."
if command -v home-manager >/dev/null 2>&1; then
  echo "Applying Home Manager configuration..."
  home-manager switch
else
  echo "home-manager not found after installation, aborting."
  exit 1
fi

echo "==> Preparing fish as default shell from Home Manager profile..."
FISH_PATH="$HOME/.nix-profile/bin/fish"
if [ -x "$FISH_PATH" ]; then
  if ! grep -qx "$FISH_PATH" /etc/shells; then
    echo "Adding $FISH_PATH to /etc/shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
  else
    echo "$FISH_PATH already present in /etc/shells."
  fi
  CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
  if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
    echo "Setting fish as the default shell for $USER..."
    chsh -s "$FISH_PATH"
  else
    echo "Fish is already the default shell for $USER."
  fi
else
  echo "Fish shell not found in $FISH_PATH. Make sure Home Manager installed it."
fi

echo "==> Bootstrap complete. You can now run 'home-manager switch'."
