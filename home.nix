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
    pkgs.tide
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
    plugins = [
      {
        name = "tide";
        src = pkgs.tide;
      }
    ];
  };

  home.activation.tideConfigure = config.lib.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.fish}/bin/fish -c 'tide configure --auto --style=Classic --prompt_colors=16 --show_time=No --lean_prompt=No --prompt_connection=Round --prompt_spacing=Compact --icons=Unicode --transient=Yes'
  '';

  home.activation.setFishDefaultShell = config.lib.dag.entryAfter ["tideConfigure"] ''
    fish_bin="$(command -v fish)"
    if [ -n "$fish_bin" ]; then
      if ! grep -qx "$fish_bin" /etc/shells; then
        echo "$fish_bin" | sudo tee -a /etc/shells >/dev/null
      fi
      if command -v chsh >/dev/null 2>&1; then
        if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$fish_bin" ]; then
          chsh -s "$fish_bin" || true
        fi
      fi
    fi
  '';
}
