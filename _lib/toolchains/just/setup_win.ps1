[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$JustVersion = $env:JUST_VERSION
if ([string]::IsNullOrEmpty($JustVersion) -or $JustVersion -eq "latest") {
    $JustVersion = "1.39.0"
}

$InstallMethod = $env:JUST_INSTALL_METHOD
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
        winget install casey.just
    } elseif ($PkgMgr -eq "choco") {
        choco install just
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\just"
    }

    $BinDir = "$Prefix\bin"
    if (-not (Test-Path -Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }

    $ZipName = "just-${JustVersion}-x86_64-pc-windows-msvc"
    $Url = "https://github.com/casey/just/releases/download/${JustVersion}/${ZipName}.zip"
    $ZipPath = "$env:TEMP\${ZipName}.zip"

    Write-Host "Downloading JUST from $Url ..."
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
    
    Expand-Archive -Path $ZipPath -DestinationPath "$env:TEMP\${ZipName}" -Force
    Move-Item -Path "$env:TEMP\${ZipName}\just.exe" -Destination "$BinDir\just.exe" -Force
    
    Remove-Item -Path $ZipPath -Force
    Remove-Item -Path "$env:TEMP\${ZipName}" -Recurse -Force
    
    Write-Host "JUST installed to $BinDir\just.exe"
}
