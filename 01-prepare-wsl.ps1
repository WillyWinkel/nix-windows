<#
.SYNOPSIS
    Prepares Windows for NixOS-WSL: enables WSL2, downloads the latest NixOS-WSL installer, and launches it.
.DESCRIPTION
    Enables required Windows features, installs WSL2, downloads the latest NixOS-WSL .wsl file if not present,
    checks WSL version, and launches the installer if NixOS is not already installed.
.NOTES
    Run as Administrator in PowerShell.
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# --- Logging Functions ---
function Log-Info    { Write-Host "[INFO]    $($args -join ' ')" -ForegroundColor Cyan }
function Log-Warn    { Write-Host "[WARNING] $($args -join ' ')" -ForegroundColor Yellow }
function Log-Error   { Write-Host "[ERROR]   $($args -join ' ')" -ForegroundColor Red }
function Log-Step    { param($step, $total, $msg) Write-Host "`n[$step/$total] $msg" -ForegroundColor Magenta }
function Log-Success { Write-Host "[SUCCESS] $($args -join ' ')" -ForegroundColor Green }

function Pause-IfInteractive {
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press Enter to continue..."
        [void][System.Console]::ReadLine()
    }
}

function Get-WSLVersion {
    Log-Info "Detecting WSL version using 'wsl.exe -v'..."
    try {
        $versionOutput = wsl.exe -v 2>&1
        if ($versionOutput -match "([0-9]+\.[0-9]+\.[0-9]+)") {
            Log-Info "Detected WSL version: $($Matches[1])"
            return [version]$Matches[1]
        }
        Log-Info "Could not parse version from 'wsl.exe -v'. Trying 'wsl.exe --version'..."
        $versionOutput2 = wsl.exe --version 2>&1
        if ($versionOutput2 -match "WSL version: ([\d\.]+)") {
            Log-Info "Detected WSL version: $($Matches[1])"
            return [version]$Matches[1]
        }
        Log-Info "Could not parse version from 'wsl.exe --version'. Trying 'wsl.exe -l -v'..."
        $listOutput = wsl.exe -l -v 2>&1
        if ($listOutput -match "WSL") {
            Log-Info "'wsl.exe -l -v' succeeded, but version is unknown (older WSL)."
            return $null
        }
    } catch {
        Log-Warn "Exception occurred while detecting WSL version: $($_.Exception.Message)"
    }
    Log-Warn "Unable to determine WSL version."
    return $null
}

try {
    Write-Host "`n=== NixOS-WSL Preparation & Installation Script ===`n" -ForegroundColor Cyan

    $step = 1
    $totalSteps = 8

    # Step 1: Check for Administrator privileges
    Log-Step $step $totalSteps "Checking for Administrator privileges..."
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Log-Error "This script must be run as Administrator."
        Pause-IfInteractive
        exit 1
    }
    $step++

    # Step 2: Enable required Windows features
    Log-Step $step $totalSteps "Enabling virtualization support (VirtualMachinePlatform)..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    Log-Success "VirtualMachinePlatform enabled (or already enabled)."
    $step++

    Log-Step $step $totalSteps "Enabling Windows Subsystem for Linux (WSL)..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    Log-Success "Microsoft-Windows-Subsystem-Linux enabled (or already enabled)."
    $step++

    # Step 3: Install WSL2 (no default distribution)
    Log-Step $step $totalSteps "Ensuring WSL2 is installed (no default distribution)..."
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Log-Error "wsl.exe not found. Please ensure WSL is available on your system."
        Pause-IfInteractive
        exit 1
    }
    wsl --install --no-distribution
    Log-Success "WSL2 installation command executed."
    $step++

    # Step 4: Download latest NixOS-WSL .wsl file if not present
    Log-Step $step $totalSteps "Checking for latest NixOS-WSL installer (.wsl file)..."
    $releaseUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
    $downloadDir = "$env:USERPROFILE\Downloads"
    try {
        $response = Invoke-RestMethod -Uri $releaseUrl
    } catch {
        Log-Error "Failed to fetch release info from GitHub. Check your internet connection."
        Pause-IfInteractive
        exit 1
    }

    $asset = $response.assets | Where-Object { $_.name -eq "nixos.wsl" } | Select-Object -First 1
    if (-not $asset) {
        Log-Error "Could not find nixos.wsl in latest release."
        Pause-IfInteractive
        exit 1
    }
    $wslPath = Join-Path $downloadDir $asset.name

    if (Test-Path $wslPath) {
        Log-Warn "File $($asset.name) already exists in $downloadDir. Skipping download."
    } else {
        Log-Info "Downloading $($asset.name) to $downloadDir ..."
        try {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $wslPath
            Log-Success "Downloaded $($asset.name) to $downloadDir"
        } catch {
            Log-Error "Failed to download $($asset.name)."
            Pause-IfInteractive
            exit 1
        }
    }
    $step++

    # Step 5: Check WSL version
    Log-Step $step $totalSteps "Checking WSL version..."
    $wslVersion = Get-WSLVersion
    if ($null -eq $wslVersion) {
        Log-Warn "Could not determine WSL version. Please ensure you have WSL >= 2.4.4 for .wsl installer support."
        Log-Warn "Attempting to continue anyway..."
    } elseif ($wslVersion -lt [version]"2.4.4") {
        Log-Error "WSL version $wslVersion detected. NixOS WSL requires WSL >= 2.4.4. Please update WSL."
        Pause-IfInteractive
        exit 1
    } else {
        Log-Success "WSL version $wslVersion detected."
    }
    $step++

    # Step 6: Check if NixOS is already installed in WSL
    Log-Step $step $totalSteps "Checking if NixOS is already installed in WSL..."
    $distroList = & wsl.exe -l --quiet 2>$null
    if ($distroList -match "^NixOS$") {
        Log-Success "NixOS is already installed in WSL. Skipping installer launch."
        Log-Info "You can start it with: wsl -d NixOS"
    } else {
        $step++
        # Step 7: Launch installer
        Log-Step $step $totalSteps "Launching $($asset.name) to install NixOS WSL..."
        try {
            Start-Process -FilePath $wslPath -ErrorAction Stop
            Log-Success "Installer launched. Follow the prompts to complete installation."
        } catch {
            Log-Error "Failed to launch installer. Please double-click $($wslPath) manually."
            Pause-IfInteractive
            exit 1
        }
    }

    Log-Success "`nAll steps completed."
} catch {
    Log-Error "$($_.Exception.Message)"
    Pause-IfInteractive
    exit 1
}
