$ErrorActionPreference = "Stop"

Get-ChildItem "$PSScriptRoot\..\rust\setup.cmd" | ForEach-Object { & $_.FullName }

if (Test-Path "$env:RUST_SERVER_DEST\Cargo.toml") {
    Write-Host "[INFO] Building Rust project..."
    pushd "$env:RUST_SERVER_DEST"
    cargo build --release
    popd
}
