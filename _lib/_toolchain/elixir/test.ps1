$ErrorActionPreference = "Stop"

if (Get-Command elixir -ErrorAction SilentlyContinue) {
    elixir --version
    Write-Output "elixir found"
} else {
    Write-Output "elixir skipped (not found)"
}
