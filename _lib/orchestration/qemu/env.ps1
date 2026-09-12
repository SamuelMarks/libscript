# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell env script for QEMU.

if (Test-Path "C:\Program Files\qemu") {
    $env:PATH = "C:\Program Files\qemu;$env:PATH"
}
