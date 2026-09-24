@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for composer on Windows.
:: Prepares and configures composer on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript composer installation on Windows.

set "THIS_FILE=%~f0"

where composer >nul 2>&1
if %errorlevel% equ 0 (
    composer --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

set "PHP_BIN=php"
where php >nul 2>&1
if errorlevel 1 (
    for /d %%P in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\PHP.PHP.*") do (
        if exist "%%P\php.exe" set "PHP_BIN=%%P\php.exe"
    )
    for /d %%P in ("%ProgramFiles%\PHP*") do (
        if exist "%%P\php.exe" set "PHP_BIN=%%P\php.exe"
    )
)

set "DEST_DIR=%USERPROFILE%\.libscript\composer\latest\bin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

echo Downloading composer.phar from https://getcomposer.org/composer.phar...
curl -sSL "https://getcomposer.org/composer.phar" -o "%DEST_DIR%\composer.phar"
if errorlevel 1 (
    echo Failed to download composer.phar.
    exit /b 1
)

(
    echo @echo off
    echo set "PHP_CMD=php"
    echo where php ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     for /d %%%%P in ^("%%LOCALAPPDATA%%\Microsoft\WinGet\Packages\PHP.PHP.*"^) do ^(
    echo         if exist "%%%%P\php.exe" set "PHP_CMD=%%%%P\php.exe"
    echo     ^)
    echo     for /d %%%%P in ^("%%ProgramFiles%%\PHP*"^) do ^(
    echo         if exist "%%%%P\php.exe" set "PHP_CMD=%%%%P\php.exe"
    echo     ^)
    echo ^)
    echo "%%PHP_CMD%%" "%%~dp0composer.phar" %%*
) > "%DEST_DIR%\composer.bat"

copy /y "%DEST_DIR%\composer.bat" "%DEST_DIR%\composer.cmd" >nul 2>&1

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "%DEST_DIR%\composer.phar" "%USERPROFILE%\.local\bin\composer.phar" >nul 2>&1
copy /y "%DEST_DIR%\composer.bat" "%USERPROFILE%\.local\bin\composer.bat" >nul 2>&1
copy /y "%DEST_DIR%\composer.cmd" "%USERPROFILE%\.local\bin\composer.cmd" >nul 2>&1

if exist "%DEST_DIR%\composer.bat" (
    echo composer installed successfully to %DEST_DIR%.
    exit /b 0
)

exit /b 1
