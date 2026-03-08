$ErrorActionPreference = "Stop"

if (-Not (Get-Command hatch -ErrorAction SilentlyContinue)) {
    if (-Not (Get-Command pipx -ErrorAction SilentlyContinue)) {
        Write-Host "Installing pipx to bootstrap hatch..."
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $pipxSetup = [System.IO.Path]::Combine($scriptDir, "..", "pipx", "setup_win.ps1")
        if (Test-Path $pipxSetup) {
            & $pipxSetup
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            $env:PATH = "$userPath;$machinePath"
        } else {
            Write-Host "pipx setup script not found."
            exit 1
        }
    }

    if (Get-Command pipx -ErrorAction SilentlyContinue) {
        Write-Host "Installing hatch via pipx..."
        pipx install hatch
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $env:PATH = "$userPath;$machinePath"
    } else {
        Write-Host "Failed to find pipx after installation attempt."
        exit 1
    }
} else {
    Write-Host "hatch is already installed."
}
