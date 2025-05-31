# NixOS WSL Automated Setup

## Steps

1. **Prepare Windows for WSL2 and download NixOS-WSL:**
   ```powershell
   .\01-prepare-wsl.ps1
   ```
   _Restart your computer when prompted._

2. **Import NixOS as a WSL2 distribution:**
   ```powershell
   .\02-import-nixos.ps1
   ```

3. **Open NixOS WSL terminal and run initial setup:**
   ```bash
   bash /mnt/c/Users/<YourUsername>/nix-windows/03-nixos-initial-setup.sh
   ```

_Note: You may need to manually set up SSH keys for Git access._
