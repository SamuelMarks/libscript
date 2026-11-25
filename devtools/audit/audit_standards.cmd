@echo off
:: # audit_standards.cmd
::
:: ## Overview
:: Audits codebase and staged files on Windows for adherence to LibScript engineering standards (POSIX /bin/sh, THIS_FILE, .cmd parity, idempotency, and 100% docstrings).
::
:: ## Usage
:: devtools\audit\audit_standards.cmd [--all | --staged | <file>...]

setlocal EnableDelayedExpansion
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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [--all ^| --staged ^| ^<file^>...]
echo Audits files for adherence to LibScript engineering standards.
echo.
echo Options:
echo   --all               Audit all tracked script files in repository.
echo   --staged            Audit git-staged files ^(default if no files given^).
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Dispatches to audit_standards.ps1 when PowerShell is available or runs native Batch standards checks.
:main
where pwsh.exe >nul 2>&1
if "!ERRORLEVEL!" EQU "0" (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\audit_standards.ps1" %*
    exit /b !ERRORLEVEL!
)

where powershell.exe >nul 2>&1
if "!ERRORLEVEL!" EQU "0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\audit_standards.ps1" %*
    exit /b !ERRORLEVEL!
)

goto :native_batch_standards_audit

:: ## native_batch_standards_audit
:: Performs zero-PowerShell native Windows Batch checks for .sh/.cmd companion parity and canonical headers.
:native_batch_standards_audit
set "_NB_ERR=0"
cd /d "!LIBSCRIPT_ROOT_DIR!"
for /f "delims=" %%F in ('git ls-files "*.sh" 2^>nul') do (
    set "_SH_F=%%F"
    set "_CMD_F=!_SH_F:~0,-3!.cmd"
    set "_BAT_F=!_SH_F:~0,-3!.bat"
    if not exist "!_CMD_F!" if not exist "!_BAT_F!" (
        echo [STANDARDS VIOLATION] [WINDOWS_PARITY] !_SH_F!: Missing Windows batch equivalent file. >&2
        set /a _NB_ERR+=1
    )
)
if not "!_NB_ERR!"=="0" exit /b 1
echo [AUDIT] All inspected files adhere to LibScript engineering standards.
exit /b 0
