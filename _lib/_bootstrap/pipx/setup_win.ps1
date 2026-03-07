$ErrorActionPreference = "Stop"

if (-Not (Get-Command pipx -ErrorAction SilentlyContinue)) {
    if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found. Please install Python first."
        exit 1
    }

    Write-Host "Installing pipx..."
    python -m pip install --user pipx
    python -m pipx ensurepath
    
    # Update PATH in current session
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:PATH = "$userPath;$env:PATH"
} else {
    Write-Host "pipx is already installed."
}
