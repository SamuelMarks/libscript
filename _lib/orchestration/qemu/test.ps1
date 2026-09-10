# ## Overview
# PowerShell test script for QEMU.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command qemu-system-x86_64 -ErrorAction SilentlyContinue) {
    & qemu-system-x86_64 --version
} elseif (Get-Command qemu-img -ErrorAction SilentlyContinue) {
    & qemu-img --version
} else {
    Write-Error "QEMU binary not found in PATH."
    exit 1
}
