[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MinioVersion = $env:CMAKE_VERSION
if ([string]::IsNullOrEmpty($MinioVersion)) {
    $MinioVersion = "latest"
}

$InstallMethod = $env:CMAKE_INSTALL_METHOD
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
        choco install cmake
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\cmake"
    }

    if ($CmakeVersion -eq "latest") {
        $CmakeVersion = "3.31.2"
    }

    $ZipName = "cmake-${CmakeVersion}-windows-x86_64"
    $Url = "https://github.com/Kitware/CMake/releases/download/v${CmakeVersion}/${ZipName}.zip"
    $ZipPath = "$env:TEMP\${ZipName}.zip"

    Write-Host "Downloading CMake from $Url ..."
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing

    Expand-Archive -Path $ZipPath -DestinationPath "$env:TEMP\" -Force
    # Copy bin and share
    Copy-Item -Path "$env:TEMP\${ZipName}\*" -Destination "$Prefix" -Recurse -Force

    Remove-Item -Path $ZipPath -Force
    Remove-Item -Path "$env:TEMP\${ZipName}" -Recurse -Force

    Write-Host "CMake installed to $Prefix"
}
