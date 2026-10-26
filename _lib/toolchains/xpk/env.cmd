@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for xpk on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for xpk.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "XPK_DIR=%LIBSCRIPT_BASE_DIR%\xpk\%XPK_VERSION%"
set "_CAND_P=%XPK_DIR%\bin"
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "xpk"
set "PYTHONPATH=%XPK_DIR%;%PYTHONPATH%"

endlocal & (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_BASE_DIR%"
    set "PATH=%PATH%"
    set "PYTHONPATH=%PYTHONPATH%"
    set "XPK_DIR=%XPK_DIR%"
)
exit /b 0
