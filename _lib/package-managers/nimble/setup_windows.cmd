@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for nimble on Windows.
:: Prepares and configures nimble on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript nimble installation on Windows.

set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

where nimble >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://nim-lang.org/download/nim-2.2.0_x64.zip"
set "TEMP_ZIP=%TEMP%\nim.zip"
set "TEMP_EXTRACT=%TEMP%\nim_extract"

echo Downloading Nim and Nimble from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Nim.
    exit /b 1
)

if not exist "%TEMP_EXTRACT%" mkdir "%TEMP_EXTRACT%"
tar -xf "%TEMP_ZIP%" -C "%TEMP_EXTRACT%"
del "%TEMP_ZIP%" >nul 2>&1

for /d %%D in ("%TEMP_EXTRACT%\nim-*") do (
    if exist "%%D\bin" (
        xcopy /y /e /q "%%D\bin\*" "%DEST_DIR%\" >nul
    )
)
for /r "%TEMP_EXTRACT%" %%F in (nimble.exe nim.exe *.dll) do (
    if exist "%%F" copy /y "%%F" "%DEST_DIR%" >nul
)

rd /s /q "%TEMP_EXTRACT%" >nul 2>&1

if exist "%DEST_DIR%\nimble.exe" (
    echo nimble installed successfully.
    exit /b 0
)

exit /b 1
