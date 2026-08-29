@echo off
setlocal EnableDelayedExpansion
:: # LibScript Python Virtual Environment Module (Windows Batch)
::
:: ## Overview
:: This module provides utilities for managing Python virtual environments
:: and resolving Python executable versions. It abstracts the underlying
:: toolchain (`venv`, `uv`, `pyenv`, etc.) behind common functions.
::
:: ## Usage
:: ```batch
:: @echo off
:: :: Resolve a Python executable
:: call "%~dp0\python_env.cmd" libscript_python_resolve "3.11"
::
:: :: Create a virtual environment
:: call "%~dp0\python_env.cmd" libscript_python_venv "C:\path\to\venv" "3.11"
:: ```

:: Subroutine dispatcher
set "THIS_FILE=%~f0"
if "%~1"=="libscript_python_venv" goto libscript_python_venv
if "%~1"=="libscript_python_resolve" goto libscript_python_resolve
goto :EOF

:libscript_python_resolve
:: ## libscript_python_resolve
:: Resolves the path to the Python executable for a given version.
::
:: **Environment Variables:**
:: - `LIBSCRIPT_PYTHON_BACKEND`: The backend to use (`uv`, `pyenv`, `native`). Defaults to `native`.
::
:: **Arguments:**
:: 1. `_version` (string, optional): The requested Python version (e.g., `3.11`).
::
:: **Returns:**
:: Prints the path to the executable and exits with 0 on success, or non-zero on failure.
setlocal EnableDelayedExpansion
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
    :: Assumes pyenv-win is in PATH
    if not "%_version%"=="" (
        set "PYENV_VERSION=%_version%"
        pyenv which python
    ) else (
        pyenv which python
    )
) else if "%_backend%"=="native" (
    :: Check if a version-specific python is available (less common on Windows but possible)
    if not "%_version%"=="" (
        :: For Windows, py launcher could be used: py -%_version% -c "import sys; print(sys.executable)"
        where py >nul 2>nul
        if not errorlevel 1 (
            for /f "delims=" %%I in ('py -%_version% -c "import sys; print(sys.executable)" 2^>nul') do (
                echo %%I
                exit /b 0
            )
        )
        :: Fallback to libscript_native installation check
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" libscript_get_version_dir python "%_version%" > "%TEMP%\libscript_py_dir.txt"
        set /p _py_dir=<"%TEMP%\libscript_py_dir.txt"
        del "%TEMP%\libscript_py_dir.txt"
        if not exist "!_py_dir!" (
            echo [INFO] Python version %_version% not found locally. Installing via libscript... >&2
            call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install python "%_version%" >&2
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


:libscript_python_venv
:: ## libscript_python_venv
:: Creates a Python virtual environment at the specified directory.
::
:: **Environment Variables:**
:: - `LIBSCRIPT_PYTHON_VENV_BACKEND`: The backend to use (`uv`, `venv`). Defaults to `venv`.
::
:: **Arguments:**
:: 1. `_target_dir` (string): The path where the virtual environment will be created.
:: 2. `_python_version` (string, optional): The specific Python version to use.
::
:: **Returns:**
:: Exits with 0 on success, non-zero on failure.
if "%~2"=="" (
    echo [ERROR] Usage: libscript_python_venv ^<target_dir^> [python_version] >&2
    exit /b 1
)

setlocal EnableDelayedExpansion
set "_target_dir=%~2"
set "_python_version=%~3"
set "_backend=%LIBSCRIPT_PYTHON_VENV_BACKEND%"
if "%_backend%"=="" set "_backend=venv"

echo [INFO] Creating Python virtual environment at "%_target_dir%" using backend "%_backend%"...

if "%_backend%"=="uv" (
    if not "%_python_version%"=="" (
        uv venv --python "%_python_version%" -- "%_target_dir%"
    ) else (
        uv venv -- "%_target_dir%"
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
    "!_python_exe!" -m venv "%_target_dir%"
) else (
    echo [ERROR] Unsupported Python venv backend: %_backend% >&2
    exit /b 1
)
exit /b 0
