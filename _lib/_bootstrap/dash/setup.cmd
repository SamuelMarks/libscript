@echo off
where dash >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping dash (via busybox) for Windows...
set "BB_URL=https://frippery.org/files/busybox/busybox.exe"
set "DASH_OUT=%TEMP%\dash.exe"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%BB_URL%' -OutFile '%DASH_OUT%'"
) else (
    certutil -urlcache -split -f "%BB_URL%" "%DASH_OUT%" >nul
)

if exist "%DASH_OUT%" (
    move /y "%DASH_OUT%" "%SystemRoot%\dash.exe" >nul 2>&1
    if not exist "%SystemRoot%\dash.exe" (
        if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
        move /y "%DASH_OUT%" "%USERPROFILE%\.local\bin\dash.exe" >nul 2>&1
        echo [WARN] Could not write to SystemRoot. Placed in %USERPROFILE%\.local\bin
    ) else (
        echo [INFO] dash installed to %SystemRoot%\dash.exe
    )
) else (
    echo [ERROR] Failed to download dash.
)
