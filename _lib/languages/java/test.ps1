$ErrorActionPreference = "Stop"

if (Get-Command java -ErrorAction SilentlyContinue) {
    java --version
    Write-Output "java found"
} else {
    Write-Output "java skipped (not found)"
}
