#!/usr/bin/env bash
set -euo pipefail

export NIX_CONFIG="experimental-features = nix-command flakes"
export HOME_MANAGER_CONFIG="$HOME/nix-windows/home.nix"

ensure_nix_env() {
  if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    export PATH="$HOME/.nix-profile/bin:$PATH"
    export NIX_PATH="nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs"
  fi
}

install_missing_packages() {
  local missing=()
  for pkg in git sudo passwd curl; do
    command -v "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Installing missing packages: ${missing[*]}"
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
  else
    echo "All base dependencies already installed."
  fi
}

update_repo() {
  local repo_url="https://github.com/WillyWinkel/nix-windows.git"
  local target_dir="$HOME/nix-windows"
  if [ ! -d "$target_dir" ]; then
    git clone "$repo_url" "$target_dir"
  else
    git -C "$target_dir" pull --ff-only
  fi
}

ensure_passwordless_sudo() {
  local user
  user="$(id -un)"
  local line="${user} ALL=(ALL) NOPASSWD:ALL"
  if ! sudo grep -qF "$line" /etc/sudoers; then
    echo "Granting passwordless sudo for $user..."
    echo "$line" | sudo EDITOR='tee -a' visudo
  else
    echo "Passwordless sudo already granted for $user."
  fi
}

install_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    echo "Installing Nix..."
    curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh
    bash /tmp/nix-install.sh --no-daemon
    ensure_nix_env
  else
    echo "Nix already installed."
  fi
}

setup_channels() {
  nix-channel --remove nixpkgs 2>/dev/null || true
  nix-channel --add https://nixos.org/channels/nixpkgs-25.05-darwin nixpkgs
  nix-channel --remove home-manager 2>/dev/null || true
  nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
  nix-channel --update
}

install_home_manager() {
  if ! command -v home-manager >/dev/null 2>&1; then
    echo "Installing Home Manager..."
    nix-shell '<home-manager>' -A install
    ensure_nix_env
  else
    echo "Home Manager already installed."
  fi
}

apply_home_manager_config() {
  echo "Applying Home Manager configuration..."
  home-manager switch -b backup
}

setup_fish_shell() {
  local fish_path="$HOME/.nix-profile/bin/fish"
  if [ -x "$fish_path" ]; then
    if ! grep -qx "$fish_path" /etc/shells; then
      echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
    local current_shell
    current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "${SHELL:-}")"
    if [ "$current_shell" != "$fish_path" ]; then
      chsh -s "$fish_path"
    fi
    "$fish_path" -c "tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Sharp --powerline_prompt_style='Two lines, character and frame' --prompt_connection=Dotted --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Many icons' --transient=No"
  else
    echo "Fish shell not found in $fish_path. Make sure Home Manager installed it."
  fi
}

main() {
  echo "==> Checking and installing base dependencies..."
  install_missing_packages

  echo "==> Ensuring ~/nix-windows exists and is up-to-date..."
  update_repo

  echo "==> Ensuring passwordless sudo..."
  ensure_passwordless_sudo

  echo "==> Checking for Nix installation..."
  install_nix

  ensure_nix_env

  echo "==> Configuring Nix channels..."
  setup_channels

  echo "==> Checking for Home Manager installation..."
  install_home_manager

  echo "==> Running home-manager switch to apply configuration..."
  apply_home_manager_config

  echo "==> Preparing fish as default shell from Home Manager profile..."
  setup_fish_shell

  echo "==> Bootstrap complete. You can now run 'home-manager switch'."
}

main "$@"
