[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MinioVersion = $env:GITLAB_VERSION
if ([string]::IsNullOrEmpty($MinioVersion)) {
    $MinioVersion = "latest"
}

Write-Error "GitLab CE natively requires a Linux environment. It is not supported via this simple script on Windows. Please use WSL or Docker Desktop to run GitLab on Windows."
exit 1
