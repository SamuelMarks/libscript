$ErrorActionPreference = "Stop"

if (-Not (Get-Command rustup -ErrorAction SilentlyContinue)) {
    $cargoBin = [System.IO.Path]::Combine([Environment]::GetFolderPath("UserProfile"), ".cargo", "bin")
    if (Test-Path -Path (Join-Path $cargoBin "rustup.exe")) {
        Write-Host "rustup is already installed in $cargoBin, but not in PATH."
    } else {
        Write-Host "Installing rustup via toolchain setup script..."
        
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $rustSetup = [System.IO.Path]::Combine($scriptDir, "..", "..", "_toolchain", "rust", "setup_win.ps1")
        
        if (Test-Path $rustSetup) {
            & $rustSetup
        } else {
            Write-Host "Downloading and installing rustup-init..."
            Invoke-WebRequest -Uri "https://win.rustup.rs" -OutFile "$env:TEMP\rustup-init.exe"
            & "$env:TEMP\rustup-init.exe" -y
        }
    }
    
    # Reload PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:PATH = "$userPath;$machinePath"
} else {
    Write-Host "rustup is already installed."
}
