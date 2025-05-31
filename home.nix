{ config, pkgs, ... }:

{
  # Use dynamic username and home directory
  home.username = config.home.username or "changeme";
  home.homeDirectory = config.home.homeDirectory or "/home/${config.home.username or "changeme"}";
  home.stateVersion = "25.05";

  # Ensure Home Manager manages ~/.nix-profile
  home.profileDirectory = "$HOME/.nix-profile";

  # Packages to install
  home.packages = with pkgs; [
    hello
    (writeShellScriptBin "my-hello" ''
      echo "Hello, ${config.home.username}!"
    '')
    fish
    curl
    vim
    neofetch
    starship
  ];

  # Custom files (dotfiles, scripts, etc.)
  home.file = {
    "bin/hm" = {
      executable = true;
      text = ''
        #!/bin/sh
        exec home-manager -f "$HOME/nix-windows/home.nix" switch "$@"
      '';
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    HOME_MANAGER_CONFIG = "$HOME/nix-windows/home.nix";
  };

  # Add ~/bin to PATH
  home.sessionPath = [ "$HOME/bin" ];

  # Enable Home Manager
  programs.home-manager.enable = true;

  # Fish shell configuration
  programs.fish = {
    enable = true;
    functions = {
      x = "exit";
    };
    plugins = [
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "Ilshidur";
          repo = "tide";
          rev = "v6.1.1";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
    ];
    shellInit = ''
      set -gx EDITOR vim
      set -U fish_greeting ""
    '';
    interactiveShellInit = ''
      set -U fish_user_paths /nix/var/nix/profiles/default/bin /run/current-system/sw/bin $HOME/.nix-profile/bin /usr/local/bin $fish_user_paths
    '';
  };

  # Starship prompt configuration
  programs.starship = {
    enable = true;
    settings = {
      # Add custom Starship settings here if desired
    };
  };

  # Run tide configure after activation
  home.activation.tideConfigure = config.lib.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.fish}/bin/fish -c "tide configure --auto \
      --style=Rainbow \
      --prompt_colors='True color' \
      --show_time='24-hour format' \
      --rainbow_prompt_separators=Angled \
      --powerline_prompt_heads=Sharp \
      --powerline_prompt_tails=Sharp \
      --powerline_prompt_style='Two lines, character and frame' \
      --prompt_connection=Dotted \
      --powerline_right_prompt_frame=No \
      --prompt_connection_andor_frame_color=Lightest \
      --prompt_spacing=Compact \
      --icons='Many icons' \
      --transient=No"
  '';
}
