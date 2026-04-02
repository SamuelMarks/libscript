Get-ChildItem "$PSScriptRoot\..\python\setup.cmd" | ForEach-Object { & $_.FullName }

if (Test-Path "$env:DEST\requirements.txt") {
    Write-Host "[INFO] Installing Python dependencies..."
    pip install -r "$env:DEST\requirements.txt"
}
