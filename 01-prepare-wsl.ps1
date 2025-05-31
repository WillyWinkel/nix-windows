$ErrorActionPreference = "Stop"

try {
    # Enable virtualization support
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

    # Install WSL2 without a default distribution
    wsl --install --no-distribution

    # Download the latest nixos-wsl.tar.gz release
    $releaseUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
    $downloadDir = "$env:USERPROFILE\Downloads"
    $response = Invoke-RestMethod -Uri $releaseUrl
    $asset = $response.assets | Where-Object { $_.name -like "nixos-wsl*.tar.gz" } | Select-Object -First 1
    if (-not $asset) {
        Write-Error "Could not find nixos-wsl tarball in latest release."
        pause
        exit 1
    }
    $tarballPath = Join-Path $downloadDir $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tarballPath

    Write-Host "Downloaded $($asset.name) to $downloadDir"
    Write-Host "Please restart your computer to continue the installation."
} catch {
    Write-Error "An error occurred: $_"
    pause
    exit 1
}
