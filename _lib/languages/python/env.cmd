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
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "python"

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
set "_PY_DIR=%LIBSCRIPT_BASE_DIR%\python\%PYTHON_VERSION%"
set "_NEW_PATH=!PATH!"
echo ";!_NEW_PATH!;" | findstr /I /C:";!_PY_DIR!\Scripts;" >nul 2>&1
if errorlevel 1 set "_NEW_PATH=!_PY_DIR!\Scripts;!_NEW_PATH!"
echo ";!_NEW_PATH!;" | findstr /I /C:";!_PY_DIR!\bin;" >nul 2>&1
if errorlevel 1 set "_NEW_PATH=!_PY_DIR!\bin;!_NEW_PATH!"
echo ";!_NEW_PATH!;" | findstr /I /C:";!_PY_DIR!;" >nul 2>&1
if errorlevel 1 set "_NEW_PATH=!_PY_DIR!;!_NEW_PATH!"

for %%U in ("%UV_PYTHON_INSTALL_DIR%" "%APPDATA%\uv\python" "%LOCALAPPDATA%\uv\python") do (
    if not "%%~U"=="" if exist "%%~U" (
        for /d %%P in ("%%~U\cpython-%PYTHON_VERSION%*") do (
            if exist "%%~fP\Scripts" (
                echo ";!_NEW_PATH!;" | findstr /I /C:";%%~fP\Scripts;" >nul 2>&1
                if errorlevel 1 set "_NEW_PATH=%%~fP\Scripts;!_NEW_PATH!"
            )
            if exist "%%~fP" (
                echo ";!_NEW_PATH!;" | findstr /I /C:";%%~fP;" >nul 2>&1
                if errorlevel 1 set "_NEW_PATH=%%~fP;!_NEW_PATH!"
            )
        )
    )
)

set "_NEW_PYPATH=!PYTHONPATH!"
if exist "!_PY_DIR!\Lib\encodings" (
    set "PYTHONHOME=!_PY_DIR!"
    echo ";!_NEW_PYPATH!;" | findstr /I /C:";!PYTHONHOME!\Lib\site-packages;" >nul 2>&1
    if errorlevel 1 (
        if "!_NEW_PYPATH!"=="" (
            set "_NEW_PYPATH=!PYTHONHOME!\Lib\site-packages"
        ) else (
            set "_NEW_PYPATH=!PYTHONHOME!\Lib\site-packages;!_NEW_PYPATH!"
        )
    )
) else (
    set "PYTHONHOME="
)

set "_NEW_VENV=%VIRTUAL_ENV%"
if not "%PYTHON_VENV%"=="" (
    echo ";!_NEW_PATH!;" | findstr /I /C:";%PYTHON_VENV%;" >nul 2>&1
    if errorlevel 1 set "_NEW_PATH=%PYTHON_VENV%;!_NEW_PATH!"
    echo ";!_NEW_PATH!;" | findstr /I /C:";%PYTHON_VENV%\Scripts;" >nul 2>&1
    if errorlevel 1 set "_NEW_PATH=%PYTHON_VENV%\Scripts;!_NEW_PATH!"
    set "_NEW_VENV=%PYTHON_VENV%"
    set "PYTHONHOME="
)

endlocal & (
    set "PYTHON_VERSION=%PYTHON_VERSION%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_BASE_DIR%"
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_BASE_DIR%"
    set "PYTHONHOME=%PYTHONHOME%"
    set "PYTHONPATH=%_NEW_PYPATH%"
    set "VIRTUAL_ENV=%_NEW_VENV%"
    set "PATH=%_NEW_PATH%"
)
exit /b 0
