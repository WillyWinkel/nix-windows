<#
.SYNOPSIS
    Prepares Windows for NixOS-WSL: enables WSL2, downloads the latest NixOS-WSL installer, and launches it.
.DESCRIPTION
    Enables required Windows features, installs WSL2, downloads the latest NixOS-WSL .wsl file if not present,
    checks WSL version, and launches the installer.
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

function Get-WSLVersion {
    Write-Host "  [Info] Trying to detect WSL version using 'wsl.exe -v'..."
    try {
        $versionOutput = wsl.exe -v 2>&1
        if ($versionOutput -match "([0-9]+\.[0-9]+\.[0-9]+)") {
            Write-Host "  [Info] Detected WSL version: $($Matches[1])"
            return [version]$Matches[1]
        }
        Write-Host "  [Info] Could not parse version from 'wsl.exe -v'. Trying 'wsl.exe --version'..."
        $versionOutput2 = wsl.exe --version 2>&1
        if ($versionOutput2 -match "WSL version: ([\d\.]+)") {
            Write-Host "  [Info] Detected WSL version: $($Matches[1])"
            return [version]$Matches[1]
        }
        Write-Host "  [Info] Could not parse version from 'wsl.exe --version'. Trying 'wsl.exe -l -v'..."
        $listOutput = wsl.exe -l -v 2>&1
        if ($listOutput -match "WSL") {
            Write-Host "  [Info] 'wsl.exe -l -v' succeeded, but version is unknown (older WSL)."
            return $null
        }
    } catch {
        Write-Host "  [Warning] Exception occurred while detecting WSL version: $($_.Exception.Message)"
    }
    Write-Host "  [Warning] Unable to determine WSL version."
    return $null
}

try {
    Write-Host "`n=== NixOS-WSL Preparation & Installation Script ===`n" -ForegroundColor Cyan

    # Step 1: Check for Administrator privileges
    Write-Host "Step 1/7: Checking for Administrator privileges..."
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }

    # Step 2: Enable required Windows features
    Write-Host "Step 2/7: Enabling virtualization support (VirtualMachinePlatform)..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    Write-Host "Step 3/7: Enabling Windows Subsystem for Linux (WSL)..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

    # Step 4: Install WSL2 (no default distribution)
    Write-Host "Step 4/7: Ensuring WSL2 is installed (no default distribution)..."
    wsl --install --no-distribution

    # Step 5: Download latest NixOS-WSL .wsl file if not present
    Write-Host "Step 5/7: Checking for latest NixOS-WSL installer (.wsl file)..."
    $releaseUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
    $downloadDir = "$env:USERPROFILE\Downloads"
    $response = Invoke-RestMethod -Uri $releaseUrl

    $asset = $response.assets | Where-Object { $_.name -eq "nixos.wsl" } | Select-Object -First 1
    if (-not $asset) {
        Write-Host "ERROR: Could not find nixos.wsl in latest release." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }
    $wslPath = Join-Path $downloadDir $asset.name

    if (Test-Path $wslPath) {
        Write-Host "Step 6/7: File $($asset.name) already exists in $downloadDir. Skipping download." -ForegroundColor Yellow
    } else {
        Write-Host "Step 6/7: Downloading $($asset.name) to $downloadDir ..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $wslPath
        Write-Host "Downloaded $($asset.name) to $downloadDir" -ForegroundColor Green
    }

    # Step 7: Check WSL version and launch installer
    Write-Host "Step 7/7: Checking WSL version and launching installer..."
    $wslVersion = Get-WSLVersion
    if ($null -eq $wslVersion) {
        Write-Host "WARNING: Could not determine WSL version. Please ensure you have WSL >= 2.4.4 for .wsl installer support." -ForegroundColor Yellow
        Write-Host "Attempting to launch the installer anyway..."
    } elseif ($wslVersion -lt [version]"2.4.4") {
        Write-Host "ERROR: WSL version $wslVersion detected. NixOS WSL requires WSL >= 2.4.4. Please update WSL." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    } else {
        Write-Host "WSL version $wslVersion detected."
    }

    Write-Host "Launching $($asset.name) to install NixOS WSL..."
    try {
        Start-Process -FilePath $wslPath -ErrorAction Stop
        Write-Host "Installer launched. Follow the prompts to complete installation."
    } catch {
        Write-Host "ERROR: Failed to launch installer. Please double-click $($wslPath) manually." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }

    Write-Host "`nAfter installation, you can run NixOS with: wsl -d NixOS"
    Pause-IfInteractive
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Pause-IfInteractive
    exit 1
}
Pause-IfInteractive  # Ensures the window stays open even after success
