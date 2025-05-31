{ pkgs, ... }:

{
  packages = [
    pkgs.pre-commit
    pkgs.git
    pkgs.nix
  ];

  enterShell = ''
    if [ -f .pre-commit-config.yaml ]; then
      pre-commit install
    fi
  '';

  processes.default.exec = "sleep infinity";
}

ntrntrntrntrnttrnrnr
