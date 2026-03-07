$ErrorActionPreference = "Stop"

if (Get-Command opam -ErrorAction SilentlyContinue) {
    opam --version
    Write-Output "opam found"
} else {
    Write-Output "opam skipped (not found)"
}
