# ## Overview
# PowerShell env script for VirtualBox.

if (Test-Path "C:\Program Files\Oracle\VirtualBox") {
    $env:PATH = "C:\Program Files\Oracle\VirtualBox;$env:PATH"
}
