$ErrorActionPreference = "Stop"

if (-Not (Get-Command nvm -ErrorAction SilentlyContinue)) {
    Write-Host "Installing nvm-windows..."
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install nvm -y
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install nvm
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install CoreyButler.NVMforWindows --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "Error: choco, scoop, or winget is required to install nvm on Windows automatically."
        exit 1
    }
    
    # Reload PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:PATH = "$userPath;$machinePath"
} else {
    Write-Host "nvm is already installed."
}
