# ## Overview
# Detects pre-existing system installations of Python 3.11+ and Node.js 18/20+ via PATH scanning.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/detect_runtimes.ps1

<#
.SYNOPSIS
Scans system PATH to auto-detect compatible Python and Node.js runtimes.
#>

$pythonCmd = (Get-Command python.exe -ErrorAction SilentlyContinue).Source
if ($pythonCmd) {
    $pyVer = & $pythonCmd --version 2>&1
    if ($pyVer -match "3\.(1[0-9]|[2-9][0-9])") {
        Write-Host "Detected compatible Python: $pythonCmd ($pyVer)"
        [System.Environment]::SetEnvironmentVariable("FOUND_PYTHON_EXE", $pythonCmd, "Process")
    }
}

$nodeCmd = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
if ($nodeCmd) {
    $nodeVer = & $nodeCmd --version 2>&1
    if ($nodeVer -match "v(1[8-9]|[2-9][0-9])") {
        Write-Host "Detected compatible Node.js: $nodeCmd ($nodeVer)"
        [System.Environment]::SetEnvironmentVariable("FOUND_NODE_EXE", $nodeCmd, "Process")
    }
}

exit 0
