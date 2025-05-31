<#
.SYNOPSIS
    Imports the downloaded NixOS-WSL rootfs as a WSL2 distribution.
.DESCRIPTION
    Finds the latest downloaded NixOS-WSL tarball and imports it into WSL2.
.NOTES
    Run as Administrator in PowerShell.
#>

$ErrorActionPreference = "Stop"

function Pause-IfInteractive {
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press Enter to continue..."
        [void][System.Console]::ReadLine()
    }
}

try {
    Write-Host "`n=== NixOS-WSL Import Script ===`n" -ForegroundColor Cyan

    # Check for Administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator."
        Pause-IfInteractive
        exit 1
    }

    Write-Host "Looking for downloaded nixos-wsl tarball in Downloads..."
    $downloadDir = "$env:USERPROFILE\Downloads"
    $nixosTar = Get-ChildItem -Path $downloadDir -Filter "nixos-wsl*.tar.gz" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $nixosTar) {
        Write-Error "nixos-wsl tarball not found in $downloadDir"
        Pause-IfInteractive
        exit 1
    }

    Write-Host "Preparing NixOS install directory..."
    $nixosInstallDir = "$env:USERPROFILE\NixOS\"
    if (-not (Test-Path $nixosInstallDir)) {
        New-Item -ItemType Directory -Path $nixosInstallDir | Out-Null
    }

    Write-Host "Importing NixOS into WSL2..."
    wsl --import NixOS $nixosInstallDir $nixosTar.FullName --version 2

    Write-Host "`nNixOS import complete." -ForegroundColor Green
    Pause-IfInteractive
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Pause-IfInteractive
    exit 1
}
