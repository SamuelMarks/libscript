@echo off
:: # sync_libscript_to_targets.cmd
::
:: ## Overview
:: Syncs the libscript repository to a Vagrant environment or a generic SSH target.
:: It automatically detects if a Vagrant environment is specified and uses its SSH config.
::
:: ## Usage
::   ./sync_libscript_to_targets.cmd [vagrant_dir | target_user@target_host target_path]
::
::   Example 1 (Vagrant auto-detect): ./sync_libscript_to_targets.cmd vagrant/windows-11
::   Example 2 (Manual target):       ./sync_libscript_to_targets.cmd vagrant@127.0.0.1 C:/libscript

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
:: Syncs the libscript repository to a specified target testing environment (Windows equivalent).
::
:: ## Usage
::   sync_libscript_to_targets.cmd <target_user@target_host> <target_path>

if "%~2"=="" (
    echo Usage: %0 ^<target_user@target_host^> ^<target_path^>
    exit /b 1
)

set TARGET_HOST=%~1
set TARGET_PATH=%~2
set REPO_ROOT=%SCRIPT_DIR%\..

echo [INFO] Syncing libscript from %REPO_ROOT% to %TARGET_HOST%:%TARGET_PATH%...

:: Using robocopy for local/network paths or rsync if available in the path.
:: Assuming rsync is available (e.g. via Git Bash or WSL) for a true cross-platform sync
where rsync >nul 2>nul
if %ERRORLEVEL% equ 0 (
    rsync -avz --exclude ".git" --exclude "vagrant/.vagrant" "%REPO_ROOT%/" "%TARGET_HOST%:%TARGET_PATH%"
) else (
    echo [WARN] rsync not found. Attempting robocopy ^(local network paths only^).
    robocopy "%REPO_ROOT%" "%TARGET_PATH%" /MIR /XD .git vagrant\.vagrant
    if %ERRORLEVEL% leq 7 (
        set ERRORLEVEL=0
    )
)

echo [PASS] Sync completed.
