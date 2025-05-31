{ pkgs, ... }:

{
  packages = [
    pkgs.git
    pkgs.nix
    pkgs.nixpkgs-fmt
  ];

  enterShell = ''
    echo "Development shell ready."
  '';

  test = pkgs.stdenv.mkDerivation {
    name = "nix-windows-tests";
    src = ./.;
    buildInputs = [ pkgs.nix pkgs.nixpkgs-fmt ];
    dontBuild = true;
    checkPhase = ''
      echo "Checking Nix syntax for home.nix..."
      nix-instantiate --parse home.nix

      echo "Checking Nix formatting for home.nix..."
      nixpkgs-fmt --check home.nix
    '';
    installPhase = ''
      cat > $out <<EOF
      #!${pkgs.bash}/bin/bash
      set -e
      echo "Checking Nix syntax for home.nix..."
      nix-instantiate --parse home.nix

      echo "Checking Nix formatting for home.nix..."
      nixpkgs-fmt --check home.nix
      EOF
      chmod +x $out
    '';
    meta.mainProgram = "test";
  };

  processes.default.exec = "sleep infinity";
}
