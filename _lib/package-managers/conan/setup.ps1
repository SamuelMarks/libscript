$ErrorActionPreference = "Stop"

if (-Not (Get-Command conan -ErrorAction SilentlyContinue)) {
    if (Get-Command pipx -ErrorAction SilentlyContinue) {
        Write-Host "Installing conan via pipx..."
        pipx install conan
    } elseif (Get-Command pip -ErrorAction SilentlyContinue) {
        Write-Host "Installing conan via pip..."
        pip install --user conan
    } else {
        Write-Host "Pip or pipx not found, trying to install via choco..."
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install conan -y
        } else {
            Write-Host "Error: Could not find pip, pipx, or choco to install conan."
            exit 1
        }
    }
    
    # Reload PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:PATH = "$userPath;$machinePath"
} else {
    Write-Host "conan is already installed."
}
