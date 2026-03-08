#!/usr/bin/env pwsh

$InstallMethod = $env:FLUENTBIT_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "system"
}

$WinPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
if ([string]::IsNullOrEmpty($WinPkgMgr)) {
    $WinPkgMgr = "winget"
}

if ($InstallMethod -eq "system" -and $WinPkgMgr -eq "choco") {
    choco install -y fluent-bit
} else {
    Write-Host "[INFO] Fluent Bit is not officially on winget. Falling back to native zip installation..."
    $Prefix = "$env:LIBSCRIPT_ROOT_DIR\installed\fluent-bit"
    if (-not (Test-Path -Path $Prefix)) {
        New-Item -ItemType Directory -Force -Path $Prefix | Out-Null
    }
    $ZipPath = Join-Path $Prefix "fluent-bit.zip"
    if (-not (Test-Path -Path $ZipPath)) {
        Write-Host "[INFO] Downloading Fluent Bit..."
        Invoke-WebRequest -Uri "https://packages.fluentbit.io/windows/fluent-bit-3.0.0-win64.zip" -OutFile $ZipPath
    }
    if (Test-Path -Path $ZipPath) {
        Write-Host "[INFO] Extracting Fluent Bit..."
        Expand-Archive -Path $ZipPath -DestinationPath $Prefix -Force
        $ExtractDir = Join-Path $Prefix "fluent-bit-3.0.0-win64"
        if (Test-Path -Path $ExtractDir) {
            Copy-Item -Path "$ExtractDir\*" -Destination $Prefix -Recurse -Force
            Remove-Item -Path $ExtractDir -Recurse -Force
        }
        Write-Host "[INFO] Fluent Bit installed successfully to $Prefix."
    } else {
        Write-Error "[ERROR] Failed to download Fluent Bit."
        exit 1
    }
}
