<#
.SYNOPSIS
    Installs NixOS WSL from the downloaded nixos.wsl file.
.DESCRIPTION
    Locates nixos.wsl in the user's Downloads folder and launches it for installation.
    Requires WSL >= 2.4.4.
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
    try {
        $versionOutput = wsl.exe --version 2>&1
        if ($versionOutput -match "WSL version: ([\d\.]+)") {
            return [version]$Matches[1]
        }
    } catch {}
    return $null
}

try {
    Write-Host "`n=== NixOS-WSL Automated Installer ===`n" -ForegroundColor Cyan

    # Check for Administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }

    Write-Host "Checking WSL version..."
    $wslVersion = Get-WSLVersion
    if (-not $wslVersion) {
        Write-Host "ERROR: Could not determine WSL version. Please ensure WSL is installed and available in PATH." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }
    if ($wslVersion -lt [version]"2.4.4") {
        Write-Host "ERROR: WSL version $wslVersion detected. NixOS WSL requires WSL >= 2.4.4. Please update WSL." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }
    Write-Host "WSL version $wslVersion detected."

    $downloadDir = "$env:USERPROFILE\Downloads"
    $wslFile = Get-ChildItem -Path $downloadDir -Filter "nixos.wsl" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $wslFile) {
        Write-Host "ERROR: Could not find nixos.wsl in $downloadDir. Please download it first." -ForegroundColor Red
        Pause-IfInteractive
        exit 1
    }
    Write-Host "Found $($wslFile.FullName)"

    Write-Host "Launching $($wslFile.Name) to install NixOS WSL..."
    try {
        Start-Process -FilePath $wslFile.FullName -ErrorAction Stop
        Write-Host "Installer launched. Follow the prompts to complete installation."
    } catch {
        Write-Host "ERROR: Failed to launch installer. Please double-click $($wslFile.FullName) manually." -ForegroundColor Red
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
