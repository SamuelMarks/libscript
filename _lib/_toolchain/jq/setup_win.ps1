#!/usr/bin/env pwsh

powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
# winget install --silent --force --id=astral-sh.uv  -e

winget install --silent --force jqlang.jq
