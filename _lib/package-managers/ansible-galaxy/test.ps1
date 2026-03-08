$ErrorActionPreference = "Stop"

if (Get-Command ansible-galaxy -ErrorAction SilentlyContinue) {
    ansible-galaxy --version
    Write-Output "ansible-galaxy found"
} else {
    Write-Output "ansible-galaxy skipped (not found)"
}
