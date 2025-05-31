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
        exec "$SHELL" -l  # Removed to allow output to be visible
        echo "Please start a new shell to apply environment changes."
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
}
