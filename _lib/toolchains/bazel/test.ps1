[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command bazel -ErrorAction SilentlyContinue) {
    bazel --version
} else {
    Write-Host "bazel skipped (not found)"
}
