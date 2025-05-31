#!/bin/sh
set -eux

# --- Install base dependencies for Nix and Home Manager ---
sudo apt-get update
sudo apt-get install -y git sudo passwd curl

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

# --- Prepare fish as default shell (do not remove this block!) ---
FISH_PATH="$(command -v fish || echo /run/current-system/sw/bin/fish)"
if [ -n "$FISH_PATH" ] && ! grep -qx "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
fi
CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
if [ -n "$FISH_PATH" ] && [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
  chsh -s "$FISH_PATH"
fi

# --- Move fonts to TODO-Fonts folder on Windows Desktop (if running under WSL) ---
if grep -qi microsoft /proc/version && [ -d /mnt/c/Windows ]; then
  echo "Moving custom fonts to Windows Desktop (TODO-Fonts)..."
  FONT_SRC="$(dirname "$0")/files/font"
  WIN_USER="$(cmd.exe /c echo %USERNAME% | tr -d '\r')"
  DESKTOP_PATH="/mnt/c/Users/$WIN_USER/Desktop/TODO-Fonts"
  if [ -d "$FONT_SRC" ]; then
    mkdir -p "$DESKTOP_PATH"
    for font in "$FONT_SRC"/*; do
      if [ -f "$font" ]; then
        cp -f "$font" "$DESKTOP_PATH/"
      fi
    done
    echo "Fonts moved to $DESKTOP_PATH."
    echo "To install the fonts: Open the 'TODO-Fonts' folder on your Windows Desktop, select all font files, right-click, and choose 'Install' or 'Install for all users'."
  else
    echo "Font source directory '$FONT_SRC' does not exist, skipping font move."
  fi
fi

# --- Install Warp terminal on Windows host (if running under WSL) ---
if grep -qi microsoft /proc/version && [ -d /mnt/c/Windows ]; then
  echo "Attempting to install Warp terminal on Windows..."
  WARP_INSTALLER_URL="https://app.warp.dev/download?platform=windows"
  WIN_USER="$(cmd.exe /c echo %USERNAME% | tr -d '\r')"
  WARP_INSTALLER_PATH="/mnt/c/Users/$WIN_USER/Downloads/warp-installer.exe"
  nix-shell -p curl --run "curl -L -o '$WARP_INSTALLER_PATH' '$WARP_INSTALLER_URL'"
  echo "Launching Warp installer..."
  cmd.exe /C start \"\" \"$(wslpath -w "$WARP_INSTALLER_PATH")\"
  echo "Warp installer launched. Please complete the installation in Windows."
fi

echo "Bootstrap complete. You can now run 'home-manager switch'."
