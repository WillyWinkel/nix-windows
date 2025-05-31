{ config, pkgs, ... }:

let
  nixpkgs-25_05 = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.05.tar.gz";
    sha256 = "sha256-1915r28xc4znrh2vf4rrjnxldw2imysz819gzhk9qlrkqanmfsxd";
  }) {};
in
{
  home.username = "willy";
  home.homeDirectory = "/home/willy";
  home.stateVersion = "25.05";

  home.packages = [
    nixpkgs-25_05.hello
    (nixpkgs-25_05.writeShellScriptBin "my-hello" ''
      echo "Hello, ${config.home.username}!"
    '')
    nixpkgs-25_05.fish
    nixpkgs-25_05.curl
    nixpkgs-25_05.vim
    nixpkgs-25_05.neofetch
  ];

  home.file = {
    # Add custom dotfiles here, e.g.:
    # ".screenrc".source = ./dotfiles/screenrc;
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    functions = {
      x = "exit";
      goland = ''
        /Users/karluwe/Applications/GoLand.app/Contents/MacOS/goland $argv
      '';
    };
    plugins = [
      {
        name = "tide";
        src = nixpkgs-25_05.fetchFromGitHub {
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

  home.activation.tideConfigure = config.lib.dag.entryAfter ["writeBoundary"] ''
    ${nixpkgs-25_05.fish}/bin/fish -c "tide configure --auto \
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
