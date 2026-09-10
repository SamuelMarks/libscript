# ## Overview
# PowerShell env script for Bento Builder stack.

$LibscriptRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
. (Join-Path $LibscriptRoot "_lib\orchestration\qemu\env.ps1")
. (Join-Path $LibscriptRoot "_lib\orchestration\virtualbox\env.ps1")
. (Join-Path $LibscriptRoot "_lib\orchestration\packer\env.ps1")
. (Join-Path $LibscriptRoot "_lib\orchestration\vagrant\env.ps1")
