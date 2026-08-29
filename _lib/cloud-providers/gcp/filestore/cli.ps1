# ## Overview
# PowerShell script for cli.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
CLI interface for GCP Filestore instances on PowerShell.

.DESCRIPTION
Wraps gcloud filestore to provision and delete instances.
#>
param(
    [Parameter(Position=0)] [string]$Action,
    [Parameter(Position=1)] [string]$InstanceName
)

$ErrorActionPreference = "Stop"

$LogCmd = Join-Path $PSScriptRoot "..\..\..\_common\log.ps1"

$ProjectFlag = ""
if ($env:GCP_PROJECT_ID) {
    $ProjectFlag = "--project=$env:GCP_PROJECT_ID"
}

$Tier = if ($env:FILESTORE_TIER) { $env:FILESTORE_TIER } else { "BASIC_HDD" }
$Capacity = if ($env:FILESTORE_CAPACITY_GB) { $env:FILESTORE_CAPACITY_GB } else { "1024" }
$Network = if ($env:FILESTORE_NETWORK) { $env:FILESTORE_NETWORK } else { "default" }

if ($Action -eq "create") {
    if (-not $InstanceName) {
        & $LogCmd -Error "Usage: filestore create <name>"
        exit 1
    }
    & $LogCmd -Info "Creating GCP Filestore $InstanceName in $env:FILESTORE_ZONE..."
    
    $TagsArg = ""
    $TagsCmd = Join-Path $PSScriptRoot "..\..\..\cloud\core\tags.cmd"
    if (Test-Path $TagsCmd) {
        & $TagsCmd :init | Out-Null
        if ($env:LIBSCRIPT_TAG_ENABLE -eq "true") {
            $TagsArg = "--labels=$env:LIBSCRIPT_TAG_KEY=$env:LIBSCRIPT_TAG_VALUE"
        }
    }
    
    $filestoreExists = gcloud filestore instances describe $InstanceName --zone=$env:FILESTORE_ZONE $ProjectFlag 2>&1
    if ($LASTEXITCODE -eq 0 -and $filestoreExists -notmatch "was not found") {
        & $LogCmd -Info "Filestore '$InstanceName' already exists in $env:FILESTORE_ZONE."
    } else {
        Invoke-Expression "gcloud filestore instances create $InstanceName --zone='$env:FILESTORE_ZONE' --tier='$Tier' --file-share='name=vol1,capacity=$($Capacity)GB' --network='name=$Network' $ProjectFlag $TagsArg"
    }
} elseif ($Action -eq "delete") {
    if (-not $InstanceName) {
        & $LogCmd -Error "Usage: filestore delete <name>"
        exit 1
    }
    $TagsCmd = Join-Path $PSScriptRoot "..\..\..\cloud\core\tags.cmd"
    if (Test-Path $TagsCmd) {
        & $TagsCmd :libscript_verify_managed gcp filestore $InstanceName $env:FILESTORE_ZONE
        if ($LASTEXITCODE -ne 0) { exit 1 }
    }
    & $LogCmd -Info "Deleting GCP Filestore $InstanceName in $env:FILESTORE_ZONE..."
    $filestoreExists = gcloud filestore instances describe $InstanceName --zone=$env:FILESTORE_ZONE $ProjectFlag 2>&1
    if ($LASTEXITCODE -eq 0 -and $filestoreExists -notmatch "was not found") {
        Invoke-Expression "gcloud filestore instances delete $InstanceName --zone='$env:FILESTORE_ZONE' --quiet $ProjectFlag"
    } else {
        & $LogCmd -Info "Filestore '$InstanceName' already deleted or not found."
    }
} else {
    & $LogCmd -Error "Unknown action: $Action"
    exit 1
}
