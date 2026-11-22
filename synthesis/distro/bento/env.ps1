# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell env script for Bento Builder stack.

$LibscriptRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
. (Join-Path $LibscriptRoot "_lib\virtualization\qemu\env.ps1")
. (Join-Path $LibscriptRoot "_lib\virtualization\virtualbox\env.ps1")
. (Join-Path $LibscriptRoot "_lib\iac\packer\env.ps1")
. (Join-Path $LibscriptRoot "_lib\iac\vagrant\env.ps1")
