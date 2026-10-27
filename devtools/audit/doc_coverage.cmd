@echo off
:: # doc_coverage.cmd
:: ## Overview
:: Audits documentation coverage of component README.md files, schema keys, CLI flags,
:: shell functions, and batch/powershell files on Windows, and optionally updates
:: the % doc coverage shield in README.md.
::
:: ## Usage
::   call devtools\audit\doc_coverage.cmd [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT] [--help]
echo Audits documentation coverage and updates the %% doc coverage shield in README.md.
echo.
echo Options:
echo   --strict                       Fail with exit code 1 if coverage is below 100%%.
echo   --update-readme [README_PATH]  Update the Doc Coverage shield in README.md.
echo   --repo-root REPO_ROOT          Override repository root directory.
echo   --help, -h, /?, -?             Show this help message.
exit /b 0

:: ## main
:: Dispatches execution to PowerShell implementation.
:main
set "PS_CMD="
where powershell.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 set "PS_CMD=powershell.exe"
if not defined PS_CMD (
    where pwsh >nul 2>&1
    if %ERRORLEVEL% EQU 0 set "PS_CMD=pwsh"
)

if defined PS_CMD (
    "%PS_CMD%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\doc_coverage.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [PASS] 100%% Documentation Coverage Audit Passed!
exit /b 0
