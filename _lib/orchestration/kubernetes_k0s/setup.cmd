@echo off
where k0s >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping k0s for Windows...
set "PACKAGE_NAME=k0s"
set "K0S_URL=https://github.com/k0sproject/k0s/releases/download/v1.30.2%2Bk0s.0/k0s-v1.30.2%2Bk0s.0-amd64.exe"
set "K0S_OUT=%TEMP%\k0s.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%K0S_URL%" "%K0S_OUT%"

if exist "%K0S_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%K0S_OUT%" "k0s.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download k0s."
    exit /b 1
)
