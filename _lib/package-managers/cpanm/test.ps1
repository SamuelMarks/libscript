$ErrorActionPreference = "Stop"

if (Get-Command cpanm -ErrorAction SilentlyContinue) {
    cpanm --version
    Write-Output "cpanm found"
} else {
    Write-Output "cpanm skipped (not found)"
}
