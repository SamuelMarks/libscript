@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for Swift on Windows.
:: Installs the official Swift Toolchain for Windows via winget package.
::
:: ## Usage
:: Automatically invoked during libscript swift installation on Windows.

set "THIS_FILE=%~f0"

where swift >nul 2>&1
if %errorlevel% equ 0 exit /b 0

for /d %%S in ("%LOCALAPPDATA%\Programs\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" exit /b 0
)
for /d %%S in ("%ProgramFiles%\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" exit /b 0
)

echo Installing Swift Toolchain via winget...
winget install --id Swift.Toolchain --silent --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo Failed to install Swift Toolchain via winget.
    exit /b 1
)

echo Swift installed successfully.
exit /b 0
