@echo off
where jq >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping standalone jq for Windows...
set "PACKAGE_NAME=jq"
set "JQ_URL=https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-win64.exe"
set "JQ_OUT=%TEMP%\jq.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%JQ_URL%" "%JQ_OUT%"

if exist "%JQ_OUT%" (
    call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%JQ_OUT%" "jq.exe"
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download jq."
    exit /b 1
)
