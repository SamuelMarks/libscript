#!/usr/bin/env pwsh
if (Get-Command etcd -ErrorAction SilentlyContinue) {
    Write-Host "etcd is installed."
    exit 0
} else {
    Write-Host "etcd is NOT installed."
    exit 1
}
