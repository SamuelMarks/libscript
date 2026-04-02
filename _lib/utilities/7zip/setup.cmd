@echo off
where 7z >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof
where 7zr >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping standalone 7zip (7zr) for Windows...
set "PACKAGE_NAME=7zip"
set "SZ_URL=https://www.7-zip.org/a/7zr.exe"
set "SZ_OUT=%TEMP%\7zr.exe"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%SZ_URL%" "%SZ_OUT%"


if exist "%SZ_OUT%" (
    move /y "%SZ_OUT%" "%SystemRoot%\7zr.exe" >nul 2>&1
    if not exist "%SystemRoot%\7zr.exe" (
        if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
        move /y "%SZ_OUT%" "%USERPROFILE%\.local\bin\7zr.exe" >nul 2>&1
        echo [WARN] Could not write to SystemRoot. Placed in %USERPROFILE%\.local\bin
    ) else (
        echo [INFO] 7zr installed to %SystemRoot%\7zr.exe
    )
) else (
    echo [ERROR] Failed to download 7zr.
)
