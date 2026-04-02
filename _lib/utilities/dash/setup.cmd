@echo off
where dash >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping dash (via busybox) for Windows...
set "PACKAGE_NAME=busybox"
set "BB_URL=https://frippery.org/files/busybox/busybox.exe"
set "DASH_OUT=%TEMP%\dash.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%BB_URL%" "%DASH_OUT%"

if exist "%DASH_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%DASH_OUT%" "dash.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download dash."
)
