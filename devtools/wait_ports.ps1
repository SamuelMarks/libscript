# ## Overview
# Waits for the required ports to become available.
#
# ## Usage
# .\wait_ports.ps1

$tries = 0
while (-not (Test-NetConnection localhost -Port 8000 -InformationLevel Quiet)) {
    Start-Sleep -Seconds 5
    Write-Host "Waiting for 8000..."
    $tries++
    if ($tries -gt 240) {
        Get-Content $env:USERPROFILE\.libscript\openedx\logs\*.log -Tail 50 -ErrorAction SilentlyContinue
        exit 1
    }
}
$tries = 0
while (-not (Test-NetConnection localhost -Port 8001 -InformationLevel Quiet)) {
    Start-Sleep -Seconds 5
    Write-Host "Waiting for 8001..."
    $tries++
    if ($tries -gt 240) {
        Get-Content $env:USERPROFILE\.libscript\openedx\logs\*.log -Tail 50 -ErrorAction SilentlyContinue
        exit 1
    }
}

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RootDir = Split-Path -Parent $ScriptDir
$HealthCmd = Join-Path $RootDir "_lib\web-apps\openedx\healthcheck.cmd"
if (Test-Path $HealthCmd) {
    & cmd.exe /c "`"$HealthCmd`""
}
