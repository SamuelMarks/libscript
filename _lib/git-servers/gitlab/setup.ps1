<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'gitlab' stack.

.DESCRIPTION
Execute this script to install and configure gitlab on the local system.
#>

$ErrorActionPreference = "Stop"

$MinioVersion = $env:GITLAB_VERSION
if ([string]::IsNullOrEmpty($MinioVersion)) {
    $MinioVersion = "latest"
}

Write-Error "GitLab CE natively requires a Linux environment. It is not supported via this simple script on Windows. Please use WSL or Docker Desktop to run GitLab on Windows."
exit 1
