$ErrorActionPreference = "Stop"

if (Get-Command sdkman -ErrorAction SilentlyContinue) {
    sdkman --version
    Write-Output "sdkman found"
} else {
    Write-Output "sdkman skipped (not found)"
}
