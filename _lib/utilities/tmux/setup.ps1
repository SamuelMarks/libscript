$ErrorActionPreference = "Stop"

$InstallMethod = $env:TMUX_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "system"
}

if ($InstallMethod -eq "system") {
    $PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
    if ([string]::IsNullOrEmpty($PkgMgr)) {
        $PkgMgr = "winget"
    }
    if ($PkgMgr -eq "winget") {
        # tmux isn't native to windows, but msys2 or cygwin might provide it.
        Write-Host "Warning: tmux is highly dependent on POSIX environments (WSL, Cygwin, MSYS2). Windows native support is limited."
    } elseif ($PkgMgr -eq "choco") {
        choco install tmux
    }
} else {
    Write-Host "Source compilation of tmux on Windows is not supported."
}
