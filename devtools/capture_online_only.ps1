# ## Overview
# Deprecated PowerShell entrypoint.
#
# ## Usage
# Do not use. Use .sh instead.

# DEPRECATED: This script cannot run inside the Windows VM because it requires QEMU monitor socket access
# on the host system to capture raw framebuffers.
# Please execute `devtools/capture_online_only.sh` directly on the host machine.
Write-Host "[ERROR] This script must be executed on the Vagrant host using the .sh equivalent."
exit 1
