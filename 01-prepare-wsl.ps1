<#
.SYNOPSIS
    Prepares Windows for WSL2 and downloads the latest NixOS-WSL installer.
.DESCRIPTION
    Enables required Windows features, installs WSL2, and downloads the latest NixOS-WSL .wsl file.
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
        Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }

    Write-Host "Step 1/4: Enabling virtualization support (VirtualMachinePlatform)..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

    Write-Host "Step 2/4: Enabling Windows Subsystem for Linux (WSL)..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

    Write-Host "Step 3/4: Installing WSL2 (no default distribution)..."
    wsl --install --no-distribution

    Write-Host "Step 4/4: Downloading latest NixOS-WSL installer (.wsl file)..."
    $releaseUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
    $downloadDir = "$env:USERPROFILE\Downloads"
    $response = Invoke-RestMethod -Uri $releaseUrl

    $assetNames = $response.assets | ForEach-Object { $_.name }
    Write-Host "Assets found in latest release: $($assetNames -join ', ')"

    $asset = $response.assets | Where-Object { $_.name -eq "nixos.wsl" } | Select-Object -First 1
    if (-not $asset) {
        Write-Host "ERROR: Could not find nixos.wsl in latest release. Assets found: $($assetNames -join ', ')" -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }
    $wslPath = Join-Path $downloadDir $asset.name

    Write-Host "Downloading $($asset.name) to $downloadDir ..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $wslPath

    Write-Host "`nSUCCESS: Downloaded $($asset.name) to $downloadDir" -ForegroundColor Green
    Write-Host "Next step: Double-click $($asset.name) to install NixOS WSL (requires WSL >= 2.4.4)." -ForegroundColor Yellow
    Write-Host "After installation, you can run NixOS with: wsl -d NixOS"
    Pause-IfInteractive
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Pause-IfInteractive
    exit 1
}
