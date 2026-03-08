[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MinioVersion = $env:BAZEL_VERSION
if ([string]::IsNullOrEmpty($MinioVersion)) {
    $MinioVersion = "latest"
}

$InstallMethod = $env:BAZEL_INSTALL_METHOD
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
        winget install bazel
    } elseif ($PkgMgr -eq "choco") {
        choco install bazel
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
    } else {
        $Prefix = $env:PREFIX
        if ([string]::IsNullOrEmpty($Prefix)) {
            $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
            $Prefix = "$LibscriptRootDir\installed\bazel"
        }

        $BinDir = "$Prefix\bin"
        if (-not (Test-Path -Path $BinDir)) {
            New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
        }

        $ExePath = "$BinDir\bazel.exe"
        if ($BazelVersion -eq "latest") {
            $BazelVersion = "v1.25.0"
        }
        $Url = "https://github.com/bazelbuild/bazelisk/releases/download/${BazelVersion}/bazelisk-windows-amd64.exe"

        Write-Host "Downloading Bazelisk (Bazel) from $Url ..."
        Invoke-WebRequest -Uri $Url -OutFile $ExePath -UseBasicParsing

        Write-Host "Bazel installed to $ExePath"
    }
