$ErrorActionPreference = "Stop"

if (Get-Command sbt -ErrorAction SilentlyContinue) {
    sbt --version
    Write-Output "sbt found"
} else {
    Write-Output "sbt skipped (not found)"
}
