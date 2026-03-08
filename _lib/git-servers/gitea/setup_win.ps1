[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MinioVersion = $env:GITEA_VERSION
if ([string]::IsNullOrEmpty($MinioVersion)) {
    $MinioVersion = "latest"
}

$InstallMethod = $env:GITEA_INSTALL_METHOD
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
        winget install MinIO.MinIO
    } elseif ($PkgMgr -eq "choco") {
        choco install gitea
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\gitea"
    }

    $BinDir = "$Prefix\bin"
    if (-not (Test-Path -Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }

    $ExePath = "$BinDir\gitea.exe"
    if ($GiteaVersion -eq "latest") {
        $GiteaVersion = "1.22.3"
    }
    $Url = "https://dl.gitea.com/gitea/${GiteaVersion}/gitea-${GiteaVersion}-windows-4.0-amd64.exe"

    Write-Host "Downloading Gitea from $Url ..."
    Invoke-WebRequest -Uri $Url -OutFile $ExePath -UseBasicParsing

    Write-Host "Gitea installed to $ExePath"
}
