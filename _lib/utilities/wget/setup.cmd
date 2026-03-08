@echo off
where wget >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping standalone wget for Windows...
set "WGET_URL=https://eternallybored.org/misc/wget/1.21.4/64/wget.exe"
set "WGET_OUT=%TEMP%\wget.exe"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%WGET_URL%' -OutFile '%WGET_OUT%'"
) else (
    certutil -urlcache -split -f "%WGET_URL%" "%WGET_OUT%" >nul
)

if exist "%WGET_OUT%" (
    move /y "%WGET_OUT%" "%SystemRoot%\wget.exe" >nul 2>&1
    if not exist "%SystemRoot%\wget.exe" (
        if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
        move /y "%WGET_OUT%" "%USERPROFILE%\.local\bin\wget.exe" >nul 2>&1
        echo [WARN] Could not write to SystemRoot. Placed in %USERPROFILE%\.local\bin
    ) else (
        echo [INFO] wget installed to %SystemRoot%\wget.exe
    )
) else (
    echo [ERROR] Failed to download wget.
)
