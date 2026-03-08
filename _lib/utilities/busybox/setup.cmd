@echo off
where busybox >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping busybox for Windows...
set "BB_URL=https://frippery.org/files/busybox/busybox.exe"
set "BB_OUT=%TEMP%\busybox.exe"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%BB_URL%' -OutFile '%BB_OUT%'"
) else (
    certutil -urlcache -split -f "%BB_URL%" "%BB_OUT%" >nul
)

if exist "%BB_OUT%" (
    move /y "%BB_OUT%" "%SystemRoot%\busybox.exe" >nul 2>&1
    if not exist "%SystemRoot%\busybox.exe" (
        if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
        move /y "%BB_OUT%" "%USERPROFILE%\.local\bin\busybox.exe" >nul 2>&1
        echo [WARN] Could not write to SystemRoot. Placed in %USERPROFILE%\.local\bin
    ) else (
        echo [INFO] busybox installed to %SystemRoot%\busybox.exe
    )
) else (
    echo [ERROR] Failed to download busybox.
)
