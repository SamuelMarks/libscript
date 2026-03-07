$ErrorActionPreference = "Stop"

if (Get-Command jq -ErrorAction SilentlyContinue) {
    jq --version
    Write-Output "jq found"
} else {
    Write-Output "jq skipped (not found)"
}
