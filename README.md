# NixOS WSL Automated Setup

## Steps

1. **Prepare Windows for WSL2 and download NixOS-WSL:**

   Run this one-liner in PowerShell to download and execute the preparation script:
   ```powershell
   iwr -useb https://github.com/WillyWinkel/nix-windows/blob/main/01-prepare-wsl.ps1 | iex
   ```
   _Restart your computer when prompted._

2. **Import NixOS as a WSL2 distribution:**
   ```powershell
   iwr -useb https://github.com/WillyWinkel/nix-windows/blob/main/02-import-nixos.ps1 | iex
   ```

3. **Open NixOS WSL terminal and run initial setup:**
   ```bash
   bash <(curl -fsSL https://github.com/WillyWinkel/nix-windows/blob/main/03-nixos-initial-setup.sh)
   ```

_Note: You may need to manually set up SSH keys for Git access._
