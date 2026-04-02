Get-ChildItem "$PSScriptRoot\..\rust\setup.cmd" | ForEach-Object { & $_.FullName }

if (Test-Path "$env:DEST\Cargo.toml") {
    Write-Host "[INFO] Building Rust project..."
    pushd "$env:DEST"
    cargo build --release
    popd
}
