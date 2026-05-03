$ErrorActionPreference = "Stop"

if (Get-Command rebar3 -ErrorAction SilentlyContinue) {
    rebar3 --version
    Write-Output "rebar3 found"
} else {
    Write-Output "rebar3 skipped (not found)"
}
