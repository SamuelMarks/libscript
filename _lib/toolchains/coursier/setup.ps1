[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MinioVersion = $env:COURSIER_VERSION
if ([string]::IsNullOrEmpty($MinioVersion)) {
    $MinioVersion = "latest"
}

$InstallMethod = $env:COURSIER_INSTALL_METHOD
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
        choco install coursier
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\coursier"
    }

    $BinDir = "$Prefix\bin"
    if (-not (Test-Path -Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }

    if ($CoursierVersion -eq "latest") {
        $CoursierVersion = "2.1.24"
    }

    $ZipName = "cs-x86_64-pc-win32.zip"
    $Url = "https://github.com/coursier/coursier/releases/download/v${CoursierVersion}/${ZipName}"
    $ZipPath = "$env:TEMP\${ZipName}"

    Write-Host "Downloading Coursier from $Url ..."
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing

    Expand-Archive -Path $ZipPath -DestinationPath "$env:TEMP\cs_extract" -Force
    Move-Item -Path "$env:TEMP\cs_extract\cs.exe" -Destination "$BinDir\coursier.exe" -Force

    Remove-Item -Path $ZipPath -Force
    Remove-Item -Path "$env:TEMP\cs_extract" -Recurse -Force

    Write-Host "Coursier installed to $BinDir\coursier.exe"
}
