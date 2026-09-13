@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where vcpkg >nul 2>&1
if %errorlevel% equ 0 (
    echo vcpkg is already installed.
    exit /b 0
)

set "VCPKG_DIR=%USERPROFILE%\vcpkg"
if not exist "%VCPKG_DIR%" (
    echo Cloning vcpkg repository...
    git clone --depth=1 https://github.com/microsoft/vcpkg.git "%VCPKG_DIR%"
)

if not exist "%VCPKG_DIR%\vcpkg.exe" (
    echo Bootstrapping vcpkg...
    call "%VCPKG_DIR%\bootstrap-vcpkg.bat" -disableMetrics
)

if exist "%VCPKG_DIR%\vcpkg.exe" (
    echo vcpkg installed successfully.
    exit /b 0
)

echo Failed to install vcpkg.
exit /b 1
