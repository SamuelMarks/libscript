@echo off
where aria2c >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping aria2 for Windows...
set "PACKAGE_NAME=aria2"
set "ARIA2_URL=https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
set "ARIA2_ZIP=%TEMP%\aria2.zip"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%ARIA2_URL%" "%ARIA2_ZIP%"

if exist "%ARIA2_ZIP%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ARIA2_ZIP%' -DestinationPath '%TEMP%\aria2-extracted' -Force"
    if exist "%TEMP%\aria2-extracted\aria2-1.37.0-win-64bit-build1\aria2c.exe" (
        call "%~dp0\..\..\_common\setup_base.cmd" :libscript_install_binary "%TEMP%\aria2-extracted\aria2-1.37.0-win-64bit-build1\aria2c.exe" "aria2c.exe"
    ) else (
        call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to find aria2c.exe in extracted files."
        exit /b 1
    )
) else (
    call "%~dp0\..\..\_common\log.cmd" :log_error "Failed to download aria2."
    exit /b 1
)
