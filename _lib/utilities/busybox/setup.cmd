@echo off
where busybox >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping busybox for Windows...
set "PACKAGE_NAME=busybox"
set "BB_URL=https://frippery.org/files/busybox/busybox.exe"
set "BB_OUT=%TEMP%\busybox.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%BB_URL%" "%BB_OUT%"

if exist "%BB_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%BB_OUT%" "busybox.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download busybox."
)
