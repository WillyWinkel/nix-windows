# NixOS WSL Automated Setup

This repository provides a robust, automated, and professional workflow for installing and configuring [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) on Windows.

It includes:
- A single PowerShell script to enable WSL2, download and install the latest NixOS WSL release (if not already installed), and launch the installer only if needed.
- An optional shell script for initial configuration inside the NixOS WSL environment.
- Example Nix and Home Manager configuration files for further customization.

The goal is to make running and managing NixOS under Windows as seamless and reproducible as possible, with clear user feedback and best practices for robustness and portability.

## Features

- Enables all required Windows features for WSL2
- Installs WSL2 (if not already installed)
- Downloads the latest NixOS-WSL installer (`nixos.wsl`) if not already present
- Installs NixOS into WSL only if not already present
- Provides an optional script for initial NixOS configuration inside WSL
- Offers example Nix and Home Manager configuration for further setup

## Requirements

- Windows 10/11 with virtualization support
- PowerShell (run as Administrator)
- Internet connection

## Quick Start

1. **Fully automate WSL2 and NixOS-WSL installation:**

   Open PowerShell **as Administrator** and run:
   ```powershell
   irm https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/01-prepare-wsl.ps1 | iex
   ```
   This script will:
   - Enable required Windows features for WSL2
   - Install WSL2 (if not already installed)
   - Download the latest `nixos.wsl` installer to your Downloads folder (if not already present)
   - Check if NixOS is already installed in WSL and only launch the installer if needed

2. **(Optional) Run initial setup in NixOS WSL:**

   In your NixOS WSL terminal, run:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/WillyWinkel/nix-windows/refs/heads/main/03-nixos-initial-setup.sh)
   ```
   This script will:
   - Update NixOS channels
   - Set NixOS as the default WSL distribution
   - Install essential tools and link your configuration

3. **(Optional) Customize your environment:**

   Use the provided `home.nix` and other configuration files in this repository as a starting point for your own NixOS and Home Manager setup.

_Note: You may need to manually set up SSH keys for Git access._

## License

MIT
