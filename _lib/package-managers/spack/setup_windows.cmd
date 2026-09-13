@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for spack on Windows.
:: Downloads and installs Spack with Python runtime integration.
::
:: ## Usage
:: Automatically invoked during libscript spack installation on Windows.

set "THIS_FILE=%~f0"

where spack >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\spack"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "BIN_DIR=%USERPROFILE%\.local\bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: Ensure Python is available
set "PYTHON_EXE="
for /d %%P in ("%LOCALAPPDATA%\Programs\Python\Python*") do (
    if exist "%%P\python.exe" set "PYTHON_EXE=%%P\python.exe"
)
if "!PYTHON_EXE!"=="" (
    for /d %%P in ("%ProgramFiles%\Python*") do (
        if exist "%%P\python.exe" set "PYTHON_EXE=%%P\python.exe"
    )
)

if "!PYTHON_EXE!"=="" (
    echo Python not found. Installing Python 3.12 via winget...
    winget install --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    for /d %%P in ("%LOCALAPPDATA%\Programs\Python\Python*") do (
        if exist "%%P\python.exe" set "PYTHON_EXE=%%P\python.exe"
    )
    if "!PYTHON_EXE!"=="" (
        for /d %%P in ("%ProgramFiles%\Python*") do (
            if exist "%%P\python.exe" set "PYTHON_EXE=%%P\python.exe"
        )
    )
)

if "!PYTHON_EXE!"=="" (
    echo Error: Python is required to run Spack.
    exit /b 1
)

set "URL=https://github.com/spack/spack/archive/refs/tags/v1.2.2.zip"
set "TEMP_ZIP=%TEMP%\spack.zip"

echo Downloading Spack from %URL%...
curl.exe -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download Spack.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

set "SPACK_SCRIPT="
for /d %%S in ("%DEST_DIR%\spack*") do (
    if exist "%%S\bin\spack" set "SPACK_SCRIPT=%%S\bin\spack"
)
if exist "%DEST_DIR%\bin\spack" set "SPACK_SCRIPT=%DEST_DIR%\bin\spack"

if "%SPACK_SCRIPT%"=="" (
    echo Error: Spack entrypoint script not found in %DEST_DIR%.
    exit /b 1
)

(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo set "PY_CMD="
    echo for /d %%%%P in ^("%%LOCALAPPDATA%%\Programs\Python\Python*"^) do ^(
    echo     if exist "%%%%P\python.exe" set "PY_CMD=%%%%P\python.exe"
    echo ^)
    echo if "^!PY_CMD^!"=="" ^(
    echo     for /d %%%%P in ^("%%ProgramFiles%%\Python*"^) do ^(
    echo         if exist "%%%%P\python.exe" set "PY_CMD=%%%%P\python.exe"
    echo     ^)
    echo ^)
    echo if "^!PY_CMD^!"=="" set "PY_CMD=python.exe"
    echo "^!PY_CMD^!" "%SPACK_SCRIPT%" %%*
) > "%BIN_DIR%\spack.cmd"

if exist "%BIN_DIR%\spack.cmd" (
    echo Spack installed successfully to %BIN_DIR%.
    exit /b 0
)

exit /b 1
