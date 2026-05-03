$ErrorActionPreference = "Stop"

if (Get-Command httpd -ErrorAction SilentlyContinue) {
    httpd --version
    Write-Output "httpd found"
} else {
    Write-Output "httpd skipped (not found)"
}
