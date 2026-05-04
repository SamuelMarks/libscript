$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh
Write-Host "Uninstalling etcd..."
choco uninstall -y etcd
