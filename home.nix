{ config, pkgs, lib, ... }:

{
  home.username = lib.mkDefault (builtins.getEnv "USER");
  home.homeDirectory = lib.mkDefault (builtins.getEnv "HOME");
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    fish
    curl
    vim
    neofetch
  ];

  home.file = {
    "bin/hm" = {
      executable = true;
      text = ''
        #!/bin/sh
        export PATH="$HOME/.nix-profile/bin:$HOME/bin:$PATH"
        cd "${config.home.homeDirectory}/nix-windows"
        git pull
        exec home-manager -f "${config.home.homeDirectory}/nix-windows/home.nix" switch "$@"
        # Reload the shell to apply environment changes
        exec "$SHELL" -l
        clear
      '';
    };
  };

  home.sessionVariables = {
    EDITOR = "vim";
    HOME_MANAGER_CONFIG = "${config.home.homeDirectory}/nix-windows/home.nix";
    PATH = "$HOME/.nix-profile/bin:$HOME/bin:$PATH";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "${config.home.homeDirectory}/bin"
  ];

  programs.home-manager.enable = true;

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
      set -g fish_greeting "🐟 time to fish :)"
    '';
    interactiveShellInit = ''
      set -g fish_user_paths /nix/var/nix/profiles/default/bin /run/current-system/sw/bin $HOME/.nix-profile/bin /usr/local/bin $fish_user_paths
    '';
  };

  programs.starship = {
    enable = true;
    settings = { };
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
