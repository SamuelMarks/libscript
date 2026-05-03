$ErrorActionPreference = "Stop"

if (Get-Command pub -ErrorAction SilentlyContinue) {
    pub --version
    Write-Output "pub found"
} else {
    Write-Output "pub skipped (not found)"
}
