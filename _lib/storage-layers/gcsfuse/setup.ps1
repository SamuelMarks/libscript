<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'gcsfuse' stack.

.DESCRIPTION
Execute this script to install and configure gcsfuse on the local system.
#>

$ErrorActionPreference = "Stop"

$GcsfuseVersion = $env:GCSFUSE_VERSION
if ([string]::IsNullOrEmpty($GcsfuseVersion)) {
    $GcsfuseVersion = "latest"
}

$InstallMethod = $env:GCSFUSE_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "source"
}

if ($InstallMethod -eq "system") {
    Write-Host "System installation of GCSFuse on Windows is typically not supported via standard package managers. Proceeding with caution or skipped."
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\gcsfuse"
    }

    $BinDir = "$Prefix\bin"
    if (-not (Test-Path -Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }

    $ExePath = "$BinDir\gcsfuse.exe"

    if (-not (Test-Path -Path $ExePath)) {
        Write-Host "Warning: GCSFuse native Windows support is very limited. This might fail."
        if ($GcsfuseVersion -eq "latest") {
            $GcsfuseVersion = "1.4.1"
        }
        $Url = "https://github.com/GoogleCloudPlatform/gcsfuse/releases/download/v${GcsfuseVersion}/gcsfuse_v${GcsfuseVersion}_windows_amd64.zip"

        Write-Host "Attempting to download gcsfuse from $Url ..."
        
        try {
            $ZipPath = "$Prefix\gcsfuse.zip"
            Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
            Expand-Archive -Path $ZipPath -DestinationPath $Prefix -Force
            Remove-Item -Path $ZipPath
            Write-Host "gcsfuse downloaded."
        } catch {
            Write-Host "Download failed. Native Windows binary might not exist for this version."
        }
    } else {
        Write-Host "gcsfuse already downloaded."
    }
}
