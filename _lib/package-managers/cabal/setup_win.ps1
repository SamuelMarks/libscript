$ErrorActionPreference = "Stop"

if (-Not (Get-Command cabal -ErrorAction SilentlyContinue)) {
    Write-Host "Installing cabal via ghcup..."
    
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ghcupSetup = [System.IO.Path]::Combine($scriptDir, "..", "ghcup", "setup_win.ps1")
    
    if (Test-Path $ghcupSetup) {
        & $ghcupSetup
    } else {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install ghcup -y
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install ghcup
        } else {
            Write-Host "Neither ghcup script nor choco/scoop found. Cannot automatically install cabal."
            exit 1
        }
    }
    
    # Reload PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:PATH = "$userPath;$machinePath"
} else {
    Write-Host "cabal is already installed."
}
