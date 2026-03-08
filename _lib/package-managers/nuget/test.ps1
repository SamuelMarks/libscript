$ErrorActionPreference = "Stop"

if (Get-Command nuget -ErrorAction SilentlyContinue) {
    nuget --version
    Write-Output "nuget found"
} else {
    Write-Output "nuget skipped (not found)"
}
