<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'duckdb' stack.

.DESCRIPTION
Execute this script to install and configure duckdb on the local system.
#>

$ErrorActionPreference = "Stop"

$DuckdbVersion = $env:DUCKDB_VERSION
if ([string]::IsNullOrEmpty($DuckdbVersion)) {
    $DuckdbVersion = "latest"
}

$InstallMethod = $env:DUCKDB_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "libscript-native"
}

if ($InstallMethod -eq "system") {
    $PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
    if ([string]::IsNullOrEmpty($PkgMgr)) {
        $PkgMgr = "winget"
    }
    if ($PkgMgr -eq "winget") {
        winget install duckdb.duckdb
    } elseif ($PkgMgr -eq "choco") {
        choco install duckdb
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\duckdb"
    }

    $BinDir = "$Prefix\bin"
    if (-not (Test-Path -Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }

    $ExePath = "$BinDir\duckdb.exe"

    if (-not (Test-Path -Path $ExePath)) {
        if ($DuckdbVersion -eq "latest") {
            $DuckdbVersion = "v0.10.2"
        }
        $Url = "https://github.com/duckdb/duckdb/releases/download/${DuckdbVersion}/duckdb_cli-windows-amd64.zip"

        Write-Host "Attempting to download duckdb from $Url ..."
        
        $ZipPath = "$Prefix\duckdb.zip"
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
        Expand-Archive -Path $ZipPath -DestinationPath $BinDir -Force
        Remove-Item -Path $ZipPath
        Write-Host "duckdb downloaded."
    } else {
        Write-Host "duckdb already downloaded."
    }
}
