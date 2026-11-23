@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup script for Gunicorn, routing WSGI/ASGI execution to Waitress and Uvicorn on Windows.
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
if "%GUNICORN_VERSION%"=="" set "GUNICORN_VERSION=latest"
if "%VERSION%"=="" set "VERSION=%GUNICORN_VERSION%"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    set "TARGET_DIR=!LIBSCRIPT_HOME!\gunicorn\!VERSION!"
    if exist "!TARGET_DIR!\bin\gunicorn.cmd" (
        echo [INFO] gunicorn !VERSION! is already installed.
        exit /b 0
    )
    echo [INFO] Gunicorn uses POSIX fork^(^). On Windows, installing Waitress and Uvicorn via root orchestrator...
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install waitress latest
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install uvicorn latest
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\python_env.cmd" :libscript_python_venv "!TARGET_DIR!" gunicorn
    if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
    if exist "!TARGET_DIR!\Scripts\gunicorn.exe" (
        > "!TARGET_DIR!\bin\gunicorn.cmd" echo @echo off
        >> "!TARGET_DIR!\bin\gunicorn.cmd" echo "%%~dp0..\Scripts\gunicorn.exe" %%*
    ) else if exist "%LIBSCRIPT_HOME%\waitress\latest\Scripts\waitress-serve.exe" (
        > "!TARGET_DIR!\bin\gunicorn.cmd" echo @echo off
        >> "!TARGET_DIR!\bin\gunicorn.cmd" echo "%LIBSCRIPT_HOME%\waitress\latest\Scripts\waitress-serve.exe" %%*
    )
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\versioning.cmd" :libscript_symlink_alias "gunicorn" "!VERSION!" "!VERSION!"
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\versioning.cmd" :libscript_symlink_alias "gunicorn" "default" "!VERSION!"
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    if exist "!LIBSCRIPT_HOME!\gunicorn\!VERSION!" rmdir /s /q "!LIBSCRIPT_HOME!\gunicorn\!VERSION!"
    exit /b 0
) else if "%ACTION%"=="test" (
    if exist "!LIBSCRIPT_HOME!\gunicorn\!VERSION!\bin\gunicorn.cmd" (
        call "!LIBSCRIPT_HOME!\gunicorn\!VERSION!\bin\gunicorn.cmd" --version
        exit /b !ERRORLEVEL!
    )
    gunicorn --version
    exit /b !ERRORLEVEL!
)

exit /b 0
