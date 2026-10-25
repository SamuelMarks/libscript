@echo off
:: # python_env.cmd
setlocal EnableDelayedExpansion
:: # LibScript Python Virtual Environment Module (Windows Batch)
::
:: ## Overview
:: This module provides utilities for managing Python virtual environments,
:: resolving Python executable versions, and ensuring virtual environment readiness.
::
:: ## Usage
:: ```batch
:: @echo off
:: call "%~dp0\python_env.cmd" libscript_python_resolve "3.11"
:: call "%~dp0\python_env.cmd" libscript_python_venv "C:\path\to\venv" "3.11"
:: call "%~dp0\python_env.cmd" libscript_python_ensure_venv_owner "C:\path\to\project" "3.12"
:: ```

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

if /i "%~1"=="libscript_python_venv" goto :libscript_python_venv
if /i "%~1"=="libscript_python_resolve" goto :libscript_python_resolve
if /i "%~1"=="libscript_python_ensure_venv_owner" goto :libscript_python_ensure_venv_owner
goto :EOF

:: ## libscript_python_resolve
:: Resolves the path to the Python executable for a given version.
:libscript_python_resolve
set "_version=%~2"
set "_backend=%LIBSCRIPT_PYTHON_BACKEND%"
if "%_backend%"=="" set "_backend=native"

if "%_backend%"=="uv" (
    if not "%_version%"=="" (
        uv python find "%_version%"
    ) else (
        uv python find
    )
) else if "%_backend%"=="pyenv" (
    if not "%_version%"=="" (
        set "PYENV_VERSION=%_version%"
        pyenv which python
    ) else (
        pyenv which python
    )
) else if "%_backend%"=="native" (
    if not "%_version%"=="" (
        where py >nul 2>nul
        if not errorlevel 1 (
            for /f "delims=" %%I in ('py -%_version% -c "import sys; print(sys.executable)" 2^>nul') do (
                echo %%I
                exit /b 0
            )
        )
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" libscript_get_version_dir python "%_version%" > "%TEMP%\libscript_py_dir.txt"
        set /p _py_dir=<"%TEMP%\libscript_py_dir.txt"
        del "%TEMP%\libscript_py_dir.txt"
        if not exist "!_py_dir!" (
            echo [INFO] Python version %_version% not found locally. Installing via libscript... >&2
            call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install python "%_version%" >&2
            if errorlevel 1 exit /b 1
        )
        if exist "!_py_dir!\python.exe" (
            echo !_py_dir!\python.exe
            exit /b 0
        ) else if exist "!_py_dir!\Scripts\python.exe" (
            echo !_py_dir!\Scripts\python.exe
            exit /b 0
        )
    )
    where python3 >nul 2>nul
    if not errorlevel 1 (
        for /f "delims=" %%I in ('where python3') do (
            echo %%I
            exit /b 0
        )
    )
    where python >nul 2>nul
    if not errorlevel 1 (
        for /f "delims=" %%I in ('where python') do (
            echo %%I
            exit /b 0
        )
    )
    echo [ERROR] No native python executable found. >&2
    exit /b 1
) else (
    echo [ERROR] Unsupported Python resolve backend: %_backend% >&2
    exit /b 1
)
exit /b 0

:: ## libscript_python_venv
:: Creates a Python virtual environment at the specified directory.
:libscript_python_venv
if "%~2"=="" (
    echo [ERROR] Usage: libscript_python_venv ^<target_dir^> [python_version] >&2
    exit /b 1
)

set "_target_dir=%~2"
set "_python_version=%~3"
set "_backend=%LIBSCRIPT_PYTHON_VENV_BACKEND%"
if "%_backend%"=="" set "_backend=venv"

echo [INFO] Creating Python virtual environment at "%_target_dir%" using backend "%_backend%"...

if "%_backend%"=="uv" (
    if not "%_python_version%"=="" (
        uv venv --seed --python "%_python_version%" -- "%_target_dir%"
    ) else (
        uv venv --seed -- "%_target_dir%"
    )
) else if "%_backend%"=="venv" (
    set "_python_exe="
    if not "%_python_version%"=="" (
        for /f "delims=" %%I in ('call "%~dp0\python_env.cmd" libscript_python_resolve "%_python_version%"') do (
            set "_python_exe=%%I"
        )
    ) else (
        for /f "delims=" %%I in ('call "%~dp0\python_env.cmd" libscript_python_resolve') do (
            set "_python_exe=%%I"
        )
    )
    if "!_python_exe!"=="" (
        echo [ERROR] Failed to resolve Python executable. >&2
        exit /b 1
    )
    set "_venv_args="
    if "%LIBSCRIPT_OFFLINE%"=="1" set "_venv_args=--without-pip"
    if "%PIP_NO_INDEX%"=="1" set "_venv_args=--without-pip"
    "!_python_exe!" -m venv !_venv_args! "%_target_dir%"
    if errorlevel 1 (
        if "!_venv_args!"=="" (
            "!_python_exe!" -m venv --without-pip "%_target_dir%"
            if errorlevel 1 exit /b 1
        ) else (
            exit /b 1
        )
    )
    if not exist "%_target_dir%\Scripts\pip.exe" (
        set "_wheels_dir=%PIP_FIND_LINKS%"
        if "!_wheels_dir!"=="" set "_wheels_dir=%PIP_WHEEL_DIR%"
        if "!_wheels_dir!"=="" set "_wheels_dir=%LIBSCRIPT_CACHE_DIR%\wheels"
        if exist "!_wheels_dir!" (
            "%_target_dir%\Scripts\python.exe" -m pip install --no-index --find-links "!_wheels_dir!" pip setuptools wheel >nul 2>&1
        )
    )
) else (
    echo [ERROR] Unsupported Python venv backend: %_backend% >&2
    exit /b 1
)
exit /b 0

:: ## libscript_python_ensure_venv_owner
:: Ensures the target project directory has a valid .venv ready for service execution on Windows.
:libscript_python_ensure_venv_owner
set "_venv_dir=%~2"
set "_venv_ver=%~3"
if "!_venv_dir!"=="" exit /b 0
if not exist "!_venv_dir!" exit /b 0
if not exist "!_venv_dir!\pyproject.toml" (
    if not exist "!_venv_dir!\requirements.txt" exit /b 0
)
if "!_venv_ver!"=="" set "_venv_ver=%PYTHON_VERSION%"
if "!_venv_ver!"=="" set "_venv_ver=3.12"
if exist "!_venv_dir!\.venv\Scripts\python.exe" exit /b 0
where uv >nul 2>&1
if not errorlevel 1 (
    set "LIBSCRIPT_PYTHON_VENV_BACKEND=uv"
    call :libscript_python_venv "" "!_venv_dir!\.venv" "!_venv_ver!" >nul 2>&1
    pushd "!_venv_dir!"
    uv sync --python "!_venv_ver!" >nul 2>&1
    popd
    exit /b 0
)
call :libscript_python_venv "" "!_venv_dir!\.venv" "!_venv_ver!" >nul 2>&1
exit /b 0
