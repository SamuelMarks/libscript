@echo off
where wget >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping standalone wget for Windows...
set "PACKAGE_NAME=wget"
set "WGET_URL=https://eternallybored.org/misc/wget/1.21.4/64/wget.exe"
set "WGET_OUT=%TEMP%\wget.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%WGET_URL%" "%WGET_OUT%"

if exist "%WGET_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%WGET_OUT%" "wget.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download wget."
)
