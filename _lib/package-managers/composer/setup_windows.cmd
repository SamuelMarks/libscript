@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where composer >nul 2>&1
if %errorlevel% equ 0 (
    echo composer is already installed.
    exit /b 0
)

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

echo Downloading composer.phar from https://getcomposer.org/composer.phar...
curl -sSL "https://getcomposer.org/composer.phar" -o "%DEST_DIR%\composer.phar"
if errorlevel 1 (
    echo Failed to download composer.phar.
    exit /b 1
)

(
    echo @echo off
    echo php "%%~dp0composer.phar" %%*
) > "%DEST_DIR%\composer.bat"

(
    echo @echo off
    echo php "%%~dp0composer.phar" %%*
) > "%DEST_DIR%\composer.cmd"

if exist "%DEST_DIR%\composer.bat" (
    echo composer installed successfully to %DEST_DIR%.
    exit /b 0
)

exit /b 1
