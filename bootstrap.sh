
set -e

# Install dependencies for Nix and Home Manager
sudo apt-get update
sudo apt-get install -y curl git sudo passwd

# Install Nix if not already installed
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Ensure Nix profile is loaded in this shell
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Install Home Manager if not already installed
if ! nix-env -q | grep -q home-manager; then
  echo "Installing Home Manager..."
  nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install
fi


# Prepare fish as default shell
FISH_PATH="$(command -v fish || echo /run/current-system/sw/bin/fish)"
grep -qx "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
[ "$CURRENT_SHELL" = "$FISH_PATH" ] || chsh -s "$FISH_PATH"

echo "Bootstrap complete. You can now run 'home-manager switch'."
