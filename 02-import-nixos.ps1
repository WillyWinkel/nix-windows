# Run as Administrator in PowerShell (x86)

$downloadDir = "$env:USERPROFILE\Downloads"
$nixosTar = Get-ChildItem -Path $downloadDir -Filter "nixos-wsl*.tar.gz" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $nixosTar) {
    Write-Error "nixos-wsl tarball not found in $downloadDir"
    exit 1
}

$nixosInstallDir = "$env:USERPROFILE\NixOS\"
if (-not (Test-Path $nixosInstallDir)) {
    New-Item -ItemType Directory -Path $nixosInstallDir | Out-Null
}

wsl --import NixOS $nixosInstallDir $nixosTar.FullName --version 2
