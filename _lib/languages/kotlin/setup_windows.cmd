@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for kotlin on Windows.
:: Prepares and configures kotlin on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript kotlin installation on Windows.

set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

where kotlinc >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\kotlin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/JetBrains/kotlin/releases/download/v2.1.10/kotlin-compiler-2.1.10.zip"
set "TEMP_ZIP=%TEMP%\kotlin.zip"

echo Downloading Kotlin compiler from %URL%...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%URL%" "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Kotlin compiler.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\kotlinc\bin\kotlinc.bat" (
    (
        echo @echo off
        echo "%DEST_DIR%\kotlinc\bin\kotlinc.bat" %%*
    ) > "%USERPROFILE%\.local\bin\kotlinc.cmd"
    echo Kotlin compiler installed successfully.
    exit /b 0
)

exit /b 1
