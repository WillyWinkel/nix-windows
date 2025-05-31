# NixOS WSL Automated Setup

## Requirements

- Windows 10/11 with virtualization support
- PowerShell (run as Administrator)
- Internet connection

## Steps

1. **Prepare Windows for WSL2 and download NixOS-WSL:**

   Run this one-liner in PowerShell **as Administrator** to download and execute the preparation script:
   ```powershell
   irm https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/01-prepare-wsl.ps1 | iex
   ```
   _Restart your computer when prompted._

2. **Import NixOS as a WSL2 distribution:**

   Run this one-liner in PowerShell **as Administrator**:
   ```powershell
   irm https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/02-import-nixos.ps1 | iex
   ```

3. **Open NixOS WSL terminal and run initial setup:**

   Run this one-liner in your NixOS WSL terminal:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/03-nixos-initial-setup.sh)
   ```

_Note: You may need to manually set up SSH keys for Git access._
