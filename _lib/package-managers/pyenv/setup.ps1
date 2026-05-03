$ErrorActionPreference = "Stop"

if (-Not (Get-Command pyenv -ErrorAction SilentlyContinue)) {
    Write-Host "Installing pyenv-win..."
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "$env:TEMP\install-pyenv-win.ps1"
    & "$env:TEMP\install-pyenv-win.ps1"
    
    # Reload PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:PATH = "$userPath;$machinePath"
} else {
    Write-Host "pyenv is already installed."
}
