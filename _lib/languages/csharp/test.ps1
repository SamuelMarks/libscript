$ErrorActionPreference = "Stop"

if (Get-Command csharp -ErrorAction SilentlyContinue) {
    csharp --version
    Write-Output "csharp found"
} else {
    Write-Output "csharp skipped (not found)"
}
