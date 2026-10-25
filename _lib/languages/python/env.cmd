@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Python on Windows.
::
:: ## Usage
:: Sets `PYTHON_VERSION` and `PYTHON_VENV`, adding them to PATH.
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
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
if "%PYTHON_VERSION%"=="" set "PYTHON_VERSION=latest"
if /i "%PYTHON_VERSION%"=="latest" (
    if exist "%LIBSCRIPT_BASE_DIR%\python\default" (
        set "PYTHON_VERSION=default"
    ) else if exist "%LIBSCRIPT_BASE_DIR%\python\latest" (
        set "PYTHON_VERSION=latest"
    ) else if exist "%LIBSCRIPT_BASE_DIR%\python\3.12" (
        set "PYTHON_VERSION=3.12"
    ) else if exist "%LIBSCRIPT_BASE_DIR%\python\3.11.9" (
        set "PYTHON_VERSION=3.11.9"
    ) else (
        set "PYTHON_VERSION=3.12"
    )
)
set "PYTHONHOME=%LIBSCRIPT_BASE_DIR%\python\%PYTHON_VERSION%"
set "_NEW_PATH=!PATH!"
echo ";!_NEW_PATH!;" | findstr /I /C:";!PYTHONHOME!\Scripts;" >nul 2>&1
if errorlevel 1 set "_NEW_PATH=!PYTHONHOME!\Scripts;!_NEW_PATH!"
echo ";!_NEW_PATH!;" | findstr /I /C:";!PYTHONHOME!\bin;" >nul 2>&1
if errorlevel 1 set "_NEW_PATH=!PYTHONHOME!\bin;!_NEW_PATH!"
echo ";!_NEW_PATH!;" | findstr /I /C:";!PYTHONHOME!;" >nul 2>&1
if errorlevel 1 set "_NEW_PATH=!PYTHONHOME!;!_NEW_PATH!"

set "_NEW_PYPATH=!PYTHONPATH!"
echo ";!_NEW_PYPATH!;" | findstr /I /C:";!PYTHONHOME!\Lib\site-packages;" >nul 2>&1
if errorlevel 1 (
    if "!_NEW_PYPATH!"=="" (
        set "_NEW_PYPATH=!PYTHONHOME!\Lib\site-packages"
    ) else (
        set "_NEW_PYPATH=!PYTHONHOME!\Lib\site-packages;!_NEW_PYPATH!"
    )
)

set "_NEW_VENV=%VIRTUAL_ENV%"
if not "%PYTHON_VENV%"=="" (
    echo ";!_NEW_PATH!;" | findstr /I /C:";%PYTHON_VENV%\Scripts;" >nul 2>&1
    if errorlevel 1 set "_NEW_PATH=%PYTHON_VENV%\Scripts;!_NEW_PATH!"
    set "_NEW_VENV=%PYTHON_VENV%"
    set "PYTHONHOME="
)

endlocal & (
    set "PYTHON_VERSION=%PYTHON_VERSION%"
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_BASE_DIR%"
    set "PYTHONHOME=%PYTHONHOME%"
    set "PYTHONPATH=%_NEW_PYPATH%"
    set "VIRTUAL_ENV=%_NEW_VENV%"
    set "PATH=%_NEW_PATH%"
)
exit /b 0
