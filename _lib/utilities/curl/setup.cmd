@echo off
where curl >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping static curl for Windows (Native curl missing)...
set "CURL_URL=https://curl.se/windows/dl-8.6.0_5/curl-8.6.0_5-win64-mingw.zip"
set "CURL_ZIP=%TEMP%\curl-win.zip"
set "DEST_DIR=%USERPROFILE%\.local\bin"

if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%CURL_URL%' -OutFile '%CURL_ZIP%'"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%CURL_ZIP%' -DestinationPath '%TEMP%\curl-extracted' -Force"
    move /y "%TEMP%\curl-extracted\curl-8.6.0_5-win64-mingw\bin\curl.exe" "%DEST_DIR%\curl.exe" >nul
) else (
    certutil -urlcache -split -f "%CURL_URL%" "%CURL_ZIP%" >nul
    echo [ERROR] No PowerShell found to extract zip. Please extract %CURL_ZIP% manually.
    exit /b 1
)

if exist "%DEST_DIR%\curl.exe" (
    echo [INFO] curl successfully bootstrapped to %DEST_DIR%\curl.exe
) else (
    echo [ERROR] Failed to bootstrap curl.
)
