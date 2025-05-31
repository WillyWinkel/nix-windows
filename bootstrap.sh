set -eux

# Install dependencies for Nix and Home Manager (no curl here)
sudo apt-get update
sudo apt-get install -y git sudo passwd

# Install Nix if not already installed
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi

# Ensure Nix profile is loaded in this shell
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Add or update Home Manager channel to 25.05
if nix-channel --list | grep -q '^home-manager '; then
  nix-channel --remove home-manager
fi
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update

# Install Home Manager if not already installed
if ! command -v home-manager >/dev/null 2>&1; then
  nix-shell '<home-manager>' -A install
fi

# Run home-manager switch to apply configuration
home-manager switch

# Prepare fish as default shell (do not remove this block!)
FISH_PATH="$(command -v fish || echo /run/current-system/sw/bin/fish)"
grep -qx "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
[ "$CURRENT_SHELL" = "$FISH_PATH" ] || chsh -s "$FISH_PATH"

# Install fonts from files/font to Windows host (if running under WSL)
if grep -qi microsoft /proc/version && [ -d /mnt/c/Windows/Fonts ]; then
  echo "Installing custom fonts to Windows..."
  for font in "$(dirname "$0")"/files/font/*; do
    if [ -f "$font" ]; then
      cp -f "$font" /mnt/c/Windows/Fonts/
    fi
  done
  echo "Fonts installed to Windows. You may need to refresh the font cache or log out/in on Windows."
fi

# Ensure curl is available via Nix (from home.nix) before using it
if grep -qi microsoft /proc/version && [ -d /mnt/c/Windows ]; then
  echo "Attempting to install Warp terminal on Windows..."
  WARP_INSTALLER_URL="https://app.warp.dev/download?platform=windows"
  WIN_USER="$(cmd.exe /c "echo %USERNAME%" | tr -d '\r')"
  WARP_INSTALLER_PATH="/mnt/c/Users/$WIN_USER/Downloads/warp-installer.exe"
  # Use curl from Nix environment
  nix-shell -p curl --run "curl -L -o '$WARP_INSTALLER_PATH' '$WARP_INSTALLER_URL'"
  echo "Launching Warp installer..."
  cmd.exe /C start "" "$(wslpath -w "$WARP_INSTALLER_PATH")"
  echo "Warp installer launched. Please complete the installation in Windows."
fi

echo "Bootstrap complete. You can now run 'home-manager switch'."
