[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command gitlab -ErrorAction SilentlyContinue) {
    gitlab-ctl status
} else {
    Write-Host "gitlab skipped (not found)"
}
