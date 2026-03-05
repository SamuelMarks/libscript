@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_win.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing Fluent Bit natively...
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\fluent-bit"
if not exist "%PREFIX%" mkdir "%PREFIX%"
:: Without powershell, native download can be done via bitsadmin or certutil.
:: Fluent Bit Windows zip URL
set "FLUENTBIT_URL=https://packages.fluentbit.io/windows/fluent-bit-3.0.0-win64.zip"
if not exist "%PREFIX%\fluent-bit.zip" (
    echo [INFO] Downloading Fluent Bit...
    bitsadmin /transfer FluentBitDownload /download /priority normal "%FLUENTBIT_URL%" "%PREFIX%\fluent-bit.zip" >nul 2>&1 || certutil -urlcache -split -f "%FLUENTBIT_URL%" "%PREFIX%\fluent-bit.zip" >nul 2>&1
)
if exist "%PREFIX%\fluent-bit.zip" (
    echo [INFO] Extracting Fluent Bit...
    tar -xf "%PREFIX%\fluent-bit.zip" -C "%PREFIX%"
    :: Move contents so bin\fluent-bit.exe is at %PREFIX%\bin\fluent-bit.exe
    xcopy /s /e /y "%PREFIX%\fluent-bit-3.0.0-win64\*" "%PREFIX%\" >nul 2>&1
    rmdir /s /q "%PREFIX%\fluent-bit-3.0.0-win64" >nul 2>&1
    echo [INFO] Fluent Bit installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Fluent Bit.
    exit /b 1
)
