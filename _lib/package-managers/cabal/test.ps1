$ErrorActionPreference = "Stop"

if (Get-Command cabal -ErrorAction SilentlyContinue) {
    cabal --version
    Write-Output "cabal found"
} else {
    Write-Output "cabal skipped (not found)"
}
