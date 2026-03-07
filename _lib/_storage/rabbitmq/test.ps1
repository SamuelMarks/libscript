$ErrorActionPreference = "Stop"

if (Get-Command rabbitmq -ErrorAction SilentlyContinue) {
    rabbitmq --version
    Write-Output "rabbitmq found"
} else {
    Write-Output "rabbitmq skipped (not found)"
}
