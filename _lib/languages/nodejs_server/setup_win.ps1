#!/usr/bin/env pwsh

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Ensure Node.js is installed
$nodejsSetup = "$PSScriptRoot\..\nodejs\setup_win.ps1"
if (Test-Path $nodejsSetup) {
    Write-Host "Ensuring Node.js is installed..."
    & $nodejsSetup
}

# 2. Determine DEST
$dest = $env:DEST
if (-not $dest) {
    $rand = -join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
    $dataDir = if ($env:LIBSCRIPT_DATA_DIR) { $env:LIBSCRIPT_DATA_DIR } else { "$env:TEMP\libscript_data" }
    if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory }
    $dest = "$dataDir\$rand"
    New-Item -Path $dest -ItemType Directory
    Set-Content -Path "$dest\main.js" -Value "console.log('Hello from Node.js server');"
    Write-Host "Created sample Node.js app at $dest"
}

# 3. Install dependencies
if (Test-Path "$dest\package.json") {
    Write-Host "Installing dependencies in $dest..."
    Push-Location $dest
    if (Test-Path "yarn.lock") {
        yarn
    } elseif (Test-Path "pnpm-lock.yaml") {
        pnpm install
    } else {
        npm install
    }
    Pop-Location
}

Write-Host "Node.js server setup complete."
