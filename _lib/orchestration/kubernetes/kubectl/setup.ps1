<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'kubectl' stack.

.DESCRIPTION
Execute this script to install and configure kubectl on the local system.
#>

$ErrorActionPreference = "Stop"

$KubectlVersion = $env:KUBECTL_VERSION
if ([string]::IsNullOrEmpty($KubectlVersion)) {
    $KubectlVersion = "latest"
}

$InstallMethod = $env:KUBECTL_INSTALL_METHOD
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
        winget install Kubernetes.kubectl
    } elseif ($PkgMgr -eq "choco") {
        choco install kubernetes-cli
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\kubectl"
    }

    $BinDir = "$Prefix\bin"
    if (-not (Test-Path -Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }

    $ExePath = "$BinDir\kubectl.exe"
    
    if ($KubectlVersion -eq "latest") {
        $KubectlVersion = (Invoke-WebRequest -Uri "https://dl.k8s.io/release/stable.txt" -UseBasicParsing).Content.Trim()
    }
    
    if (-not (Test-Path -Path $ExePath)) {
        $Url = "https://dl.k8s.io/release/${KubectlVersion}/bin/windows/amd64/kubectl.exe"

        Write-Host "Downloading kubectl from $Url ..."
        Invoke-WebRequest -Uri $Url -OutFile $ExePath -UseBasicParsing

        Write-Host "kubectl installed to $ExePath"
    } else {
        Write-Host "kubectl already installed at $ExePath"
    }
}
