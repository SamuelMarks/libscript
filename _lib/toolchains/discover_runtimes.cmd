@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

:: ## Overview
:: Scans the host system to discover installed toolchains and runtimes (e.g., Python).
:: Checks standard system locations, PATH, and previous libscript installation paths.
::
:: ## Usage
::   call discover_runtimes.cmd [--json | --eval]

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "MODE=%~1"
if "%MODE%"=="" set "MODE=--eval"

set "PY_PATH="

:: ## discover_python
:: Probes for Python in standard PATH, Registry, and legacy libscript bundles.
call :discover_python

if "%MODE%"=="--json" (
    echo {
    echo   "python": {
    if defined PY_PATH (
        echo     "path": "!PY_PATH:\=\\!",
        echo     "found": true
    ) else (
        echo     "found": false
    )
    echo   }
    echo }
    exit /b 0
)

if "%MODE%"=="--eval" (
    if defined PY_PATH (
        echo python_path="%PY_PATH%"
    )
    exit /b 0
)

echo Usage: %0 [--json ^| --eval] >&2
exit /b 1

:discover_python
:: Try PATH
for %%P in (python.exe) do set "PY_PATH=%%~$PATH:P"
if defined PY_PATH exit /b 0

:: Try libscript bundled paths
set "COMMON_PATHS=C:\libscript\python\python.exe C:\Program Files\libscript\python\python.exe"
for %%P in (%COMMON_PATHS%) do (
    if exist "%%P" (
        set "PY_PATH=%%P"
        exit /b 0
    )
)
exit /b 0
