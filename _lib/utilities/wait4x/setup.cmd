@echo off
where wait4x >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping wait4x for Windows...
set "PACKAGE_NAME=wait4x"
set "WAIT4X_URL=https://github.com/atkrad/wait4x/releases/download/v2.13.0/wait4x-windows-amd64.tar.gz"
set "WAIT4X_TAR=%TEMP%\wait4x.tar.gz"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%WAIT4X_URL%" "%WAIT4X_TAR%"

if exist "%WAIT4X_TAR%" (
    tar -xf "%WAIT4X_TAR%" -C "%TEMP%" wait4x.exe
    if exist "%TEMP%\wait4x.exe" (
        call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%TEMP%\wait4x.exe" "wait4x.exe"
    ) else (
        call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to find wait4x.exe in archive."
        exit /b 1
    )
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download wait4x."
    exit /b 1
)
