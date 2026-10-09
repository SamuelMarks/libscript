@echo off
:: # precommit_dance.cmd
::
:: ## Overview
:: Runs the pre-commit hook dance in CI to ensure code quality on Windows.
::
:: ## Usage
:: Execute this script without arguments.

setlocal EnableDelayedExpansion
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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="/?" goto :help
if "%~1"=="-?" goto :help
goto :main

:: ## help
:: Displays usage instructions.
:help
echo Usage: %~nx0
echo Runs the pre-commit hook dance in CI to ensure code quality on Windows.
exit /b 0

:: ## main
:: Executes pre-commit hooks dance in CI environment.
:main
echo ^>^>^> RUNNING PRE-COMMIT DANCE ^<^<^<

:: Ensure we run from the git repository root
cd /d "%~dp0\..\.."

:: Stage all files so the pre-commit hook thinks they are staged
git add -A

:: Run the pre-commit script
call .githooks\pre-commit.cmd

:: Check if anything changed
git diff --no-ext-diff --cached --exit-code
if %ERRORLEVEL% neq 0 (
    echo Error: The pre-commit hook modified files. Please run the pre-commit hook locally and commit the changes.
    exit /b 1
)

echo Pre-commit dance completed successfully.
exit /b 0
