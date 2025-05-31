# NixOS WSL Automated Setup

## Requirements

- Windows 10/11 with virtualization support
- PowerShell (run as Administrator)
- Internet connection
- WSL version >= 2.4.4

## Steps

1. **Enable WSL2 and download NixOS-WSL:**

   Run this one-liner in PowerShell **as Administrator** to enable WSL2 and download the latest NixOS-WSL installer:
   ```powershell
   irm https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/01-prepare-wsl.ps1 | iex
   ```
   This script will:
   - Enable required Windows features for WSL2
   - Install WSL2 (if not already installed)
   - Download the latest `nixos.wsl` installer to your Downloads folder

2. **Install NixOS WSL:**

   Run this one-liner in PowerShell **as Administrator** to launch the installer automatically:
   ```powershell
   irm https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/02-import-nixos.ps1 | iex
   ```
   Or, double-click the downloaded `nixos.wsl` file in your Downloads folder.  
   (Requires WSL >= 2.4.4. This will install NixOS as a WSL distribution.)

3. **Run NixOS:**

   Open a terminal and run:
   ```powershell
   wsl -d NixOS
   ```

4. **(Optional) Run initial setup in NixOS WSL:**

   Run this one-liner in your NixOS WSL terminal:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/03-nixos-initial-setup.sh)
   ```
   This script will:
   - Update NixOS channels
   - Set NixOS as the default WSL distribution
   - Install essential tools and link your configuration

_Note: You may need to manually set up SSH keys for Git access._
