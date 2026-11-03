@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup script for Uvicorn ASGI server.
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
    set "BIN_DIR=%USERPROFILE%\.libscript\uvicorn\latest\bin"
    if exist "!BIN_DIR!\uvicorn.cmd" exit /b 0
    where uvicorn >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] uvicorn is already installed on Windows.
        exit /b 0
    )
    set "_PY_EXE="
    for /d %%P in ("C:\Python*" "%ProgramFiles%\Python*" "%LOCALAPPDATA%\Programs\Python\Python*") do (
        if exist "%%~fP\python.exe" if not defined _PY_EXE set "_PY_EXE=%%~fP\python.exe"
    )
    if defined _PY_EXE (
        echo [INFO] Installing uvicorn via !_PY_EXE! -m pip...
        "!_PY_EXE!" -m pip install --quiet uvicorn 2>nul || "!_PY_EXE!" -m pip install --user --quiet uvicorn 2>nul
        if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
        > "!BIN_DIR!\uvicorn.cmd" echo @echo off
        >> "!BIN_DIR!\uvicorn.cmd" echo "!_PY_EXE!" -m uvicorn %%*
        exit /b 0
    )
    where uv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing uvicorn via uv...
        uv tool install uvicorn >nul 2>&1 || uv pip install uvicorn
        exit /b 0
    )
    where pip >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing uvicorn via pip...
        pip install --user uvicorn
        if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
        > "!BIN_DIR!\uvicorn.cmd" echo @echo off
        >> "!BIN_DIR!\uvicorn.cmd" echo python -m uvicorn %%*
        exit /b 0
    )
    echo [ERROR] Python environment with pip or uv required to install uvicorn.
    exit /b 1
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall uvicorn >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y uvicorn >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    uvicorn --version
    exit /b %ERRORLEVEL%
)

exit /b 0
