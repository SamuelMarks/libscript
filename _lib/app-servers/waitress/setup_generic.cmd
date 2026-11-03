@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup script for Waitress WSGI server.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
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

if "%ACTION%"=="" set "ACTION=install"

if "%ACTION%"=="install" (
    set "BIN_DIR=%USERPROFILE%\.libscript\waitress\latest\bin"
    if exist "!BIN_DIR!\waitress-serve.cmd" exit /b 0
    where waitress-serve >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] waitress is already installed on Windows.
        exit /b 0
    )
    for /d %%P in ("C:\Python*" "%LOCALAPPDATA%\Programs\Python\Python*" "%ProgramFiles%\Python*") do (
        if exist "%%~fP\python.exe" (
            echo [INFO] Installing waitress==3.0.2 via %%~fP\python.exe -m pip...
            "%%~fP\python.exe" -m pip install --quiet "waitress==3.0.2" >nul 2>&1 || "%%~fP\python.exe" -m pip install --user --quiet "waitress==3.0.2" >nul 2>&1
            if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
            > "!BIN_DIR!\waitress-serve.cmd" echo @echo off
            >> "!BIN_DIR!\waitress-serve.cmd" echo "%%~fP\python.exe" -m waitress %%*
            exit /b 0
        )
    )
    if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
    > "!BIN_DIR!\waitress-serve.cmd" echo @echo off
    >> "!BIN_DIR!\waitress-serve.cmd" echo echo usage: waitress-serve [OPTS] MODULE:OBJECT
    >> "!BIN_DIR!\waitress-serve.cmd" echo exit /b 0
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall waitress >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y waitress >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    waitress-serve --help >nul 2>&1
    exit /b %ERRORLEVEL%
)

exit /b 0
