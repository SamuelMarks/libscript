$ErrorActionPreference = "Stop"

if (Get-Command conan -ErrorAction SilentlyContinue) {
    conan --version
    Write-Output "conan found"
} else {
    Write-Output "conan skipped (not found)"
}
