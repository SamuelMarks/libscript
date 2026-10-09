@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for huggingface-cli on Windows.
:: Prepares and configures huggingface-cli on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript huggingface-cli installation on Windows.

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

where huggingface-cli >nul 2>&1
if %errorlevel% equ 0 (
    huggingface-cli --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

where python >nul 2>&1
if errorlevel 1 (
    echo Python not found on PATH.
    exit /b 1
)

echo Installing huggingface_hub via pip...
python -m pip install --upgrade --quiet huggingface_hub
if errorlevel 1 (
    echo Failed to install huggingface_hub via pip.
    exit /b 1
)

set "BIN_DIR=%USERPROFILE%\.libscript\huggingface-cli\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
(
    echo @echo off
    echo python -m huggingface_hub.cli.hf %%*
) > "!BIN_DIR!\huggingface-cli.cmd"

copy /y "!BIN_DIR!\huggingface-cli.cmd" "!BIN_DIR!\hf.cmd" >nul 2>&1

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\huggingface-cli.cmd" "%USERPROFILE%\.local\bin\huggingface-cli.cmd" >nul 2>&1
copy /y "!BIN_DIR!\hf.cmd" "%USERPROFILE%\.local\bin\hf.cmd" >nul 2>&1

exit /b 0
