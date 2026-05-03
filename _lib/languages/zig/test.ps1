$ErrorActionPreference = "Stop"

if (Get-Command zig -ErrorAction SilentlyContinue) {
    zig --version
    Write-Output "zig found"
} else {
    Write-Output "zig skipped (not found)"
}
