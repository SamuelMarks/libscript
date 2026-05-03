[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$NatsVersion = $env:NATS_VERSION
if ([string]::IsNullOrEmpty($NatsVersion) -or $NatsVersion -eq "latest") {
    $NatsVersion = "v2.10.25"
}

$InstallMethod = $env:NATS_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "source"
}

if ($InstallMethod -eq "system") {
    $PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
    if ([string]::IsNullOrEmpty($PkgMgr)) {
        $PkgMgr = "winget"
    }
    if ($PkgMgr -eq "winget") {
        winget install nats-io.nats-server
    } elseif ($PkgMgr -eq "choco") {
        choco install nats-server
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\nats"
    }

    $BinDir = "$Prefix\bin"
    if (-not (Test-Path -Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }

    $ZipName = "nats-server-${NatsVersion}-windows-amd64"
    $Url = "https://github.com/nats-io/nats-server/releases/download/${NatsVersion}/${ZipName}.zip"
    $ZipPath = "$env:TEMP\${ZipName}.zip"

    Write-Host "Downloading NATS from $Url ..."
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
    
    Expand-Archive -Path $ZipPath -DestinationPath "$env:TEMP\" -Force
    Move-Item -Path "$env:TEMP\${ZipName}\nats-server.exe" -Destination "$BinDir\nats-server.exe" -Force
    
    Remove-Item -Path $ZipPath -Force
    Remove-Item -Path "$env:TEMP\${ZipName}" -Recurse -Force
    
    Write-Host "NATS installed to $BinDir\nats-server.exe"
}
