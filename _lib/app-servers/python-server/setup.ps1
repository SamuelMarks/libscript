$ErrorActionPreference = "Stop"

Get-ChildItem "$PSScriptRoot\..\python\setup.cmd" | ForEach-Object { & $_.FullName }

if (Test-Path "$env:PYTHON_SERVER_DEST\requirements.txt") {
    Write-Host "[INFO] Installing Python dependencies..."
    pip install -r "$env:PYTHON_SERVER_DEST\requirements.txt"
}
