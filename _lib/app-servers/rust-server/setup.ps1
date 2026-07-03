<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'rust-server' stack.

.DESCRIPTION
Execute this script to install and configure rust-server on the local system.
#>

$ErrorActionPreference = "Stop"

Get-ChildItem "$PSScriptRoot\..\rust\setup.cmd" | ForEach-Object { & $_.FullName }

if (Test-Path "$env:RUST_SERVER_DEST\Cargo.toml") {
    Write-Host "[INFO] Building Rust project..."
    pushd "$env:RUST_SERVER_DEST"
    cargo build --release
    popd
}
