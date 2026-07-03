<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'cpanm' stack.

.DESCRIPTION
Execute this script to install and configure cpanm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command perl -ErrorAction SilentlyContinue)) {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing Strawberry Perl via Chocolatey..."
        choco install strawberryperl -y
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $env:PATH = "$userPath;$machinePath"
    } else {
        Write-Host "Perl not found, and chocolatey not found to install it."
        exit 1
    }
}

if (-Not (Get-Command cpanm -ErrorAction SilentlyContinue)) {
    Write-Host "Installing cpanm via cpan..."
    # Strawberry Perl usually has cpanm, but just in case
    cpan App::cpanminus
} else {
    Write-Host "cpanm is already installed."
}
