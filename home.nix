{ config, pkgs, ... }:

{
  home.username = "willy";
  home.homeDirectory = "/home/willy";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.hello
    (pkgs.writeShellScriptBin "my-hello" ''
      echo "Hello, ${config.home.username}!"
    '')
    pkgs.fish
    pkgs.curl
    pkgs.vim
    pkgs.neofetch
  ];

  home.file = {
    # Example:
    # ".screenrc".source = dotfiles/screenrc;
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
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
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
