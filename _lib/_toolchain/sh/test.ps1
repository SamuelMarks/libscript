$ErrorActionPreference = "Stop"

if (Get-Command sh -ErrorAction SilentlyContinue) {
    sh --version
    Write-Output "sh found"
} else {
    Write-Output "sh skipped (not found)"
}
