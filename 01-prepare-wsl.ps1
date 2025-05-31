<#
.SYNOPSIS
    Prepares Windows for WSL2 and downloads the latest NixOS-WSL rootfs.
.DESCRIPTION
    Enables required Windows features, installs WSL2, and downloads the latest NixOS-WSL tarball.
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
    Write-Host "`n=== NixOS-WSL Preparation Script ===`n" -ForegroundColor Cyan

    # Check for Administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator."
        Pause-IfInteractive
        exit 1
    }

    # Enable VirtualMachinePlatform
    Write-Host "Enabling virtualization support (VirtualMachinePlatform)..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    # Enable WSL
    Write-Host "Enabling Windows Subsystem for Linux (WSL)..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

    # Install WSL2 (no default distro)
    Write-Host "Installing WSL2 (no default distribution)..."
    wsl --install --no-distribution

    # Download latest NixOS-WSL release
    Write-Host "Fetching latest NixOS-WSL release info from GitHub..."
    $releaseUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
    $downloadDir = "$env:USERPROFILE\Downloads"
    $response = Invoke-RestMethod -Uri $releaseUrl

    $assetNames = $response.assets | ForEach-Object { $_.name }
    Write-Host "Assets found in latest release: $($assetNames -join ', ')"

    $asset = $response.assets | Where-Object { $_.name -like "nixos-wsl*.tar.gz" } | Select-Object -First 1
    if (-not $asset) {
        Write-Error "Could not find nixos-wsl*.tar.gz tarball in latest release. Assets found: $($assetNames -join ', ')"
        Pause-IfInteractive
        exit 1
    }
    $tarballPath = Join-Path $downloadDir $asset.name

    Write-Host "Downloading $($asset.name) to $downloadDir ..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tarballPath

    Write-Host "`nDownloaded $($asset.name) to $downloadDir" -ForegroundColor Green
    Write-Host "Please restart your computer to continue the installation." -ForegroundColor Yellow
    Pause-IfInteractive
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Pause-IfInteractive
    exit 1
}
