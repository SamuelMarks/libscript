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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="/?" goto :help
if "%~1"=="-?" goto :help
goto :main

:help
echo Usage: %~nx0
echo Runs the pre-commit hook dance in CI to ensure code quality on Windows.
exit /b 0

:main
echo ^>^>^> RUNNING PRE-COMMIT DANCE ^<^<^<

:: Ensure we run from the git repository root
cd /d "%~dp0\..\.."

:: Stage all files so the pre-commit hook thinks they are staged
git add -A

:: Run the pre-commit script
call .githooks\pre-commit.cmd

:: Check if anything changed
git diff --cached --exit-code
if %ERRORLEVEL% neq 0 (
    echo Error: The pre-commit hook modified files. Please run the pre-commit hook locally and commit the changes.
    exit /b 1
)

echo Pre-commit dance completed successfully.
exit /b 0
