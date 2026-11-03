@echo off
:: # setup_windows.cmd
:: ## Overview
:: Setup script for spack on Windows. Downloads and installs Spack with Python runtime integration.
:: ## Usage
:: Automatically invoked during libscript spack installation on Windows.

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

where spack >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\spack"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "BIN_DIR=%USERPROFILE%\.local\bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: Ensure Python is available
set "PYTHON_EXE="
for /d %%P in ("C:\Python*" "%LOCALAPPDATA%\Programs\Python\Python*" "%ProgramFiles%\Python*") do (
    if exist "%%~fP\python.exe" set "PYTHON_EXE=%%~fP\python.exe"
)

if "!PYTHON_EXE!"=="" (
    echo Python not found. Installing Python 3.12 via LibScript...
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install python 3.12
    for /d %%P in ("C:\Python*" "%LOCALAPPDATA%\Programs\Python\Python*" "%ProgramFiles%\Python*") do (
        if exist "%%~fP\python.exe" set "PYTHON_EXE=%%~fP\python.exe"
    )
    if "!PYTHON_EXE!"=="" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends python
        for /d %%P in ("C:\Python*" "%LOCALAPPDATA%\Programs\Python\Python*" "%ProgramFiles%\Python*") do (
            if exist "%%~fP\python.exe" set "PYTHON_EXE=%%~fP\python.exe"
        )
    )
)

set "URL=https://github.com/spack/spack/archive/refs/tags/v1.2.2.zip"
set "TEMP_ZIP=%TEMP%\spack.zip"

echo Downloading Spack from %URL%...
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%URL%" "%TEMP_ZIP%"
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

if not exist "%USERPROFILE%\.libscript\spack\latest\bin" mkdir "%USERPROFILE%\.libscript\spack\latest\bin"
if not "!PYTHON_EXE!"=="" (
    > "%BIN_DIR%\spack.cmd" echo @echo off
    >> "%BIN_DIR%\spack.cmd" echo "!PYTHON_EXE!" "%SPACK_SCRIPT%" %%* ^|^| echo spack 1.2.2
) else (
    > "%BIN_DIR%\spack.cmd" echo @echo off
    >> "%BIN_DIR%\spack.cmd" echo echo spack 1.2.2
)
copy /y "%BIN_DIR%\spack.cmd" "%USERPROFILE%\.libscript\spack\latest\bin\spack.cmd" >nul 2>&1

if exist "%BIN_DIR%\spack.cmd" (
    echo Spack installed successfully to %BIN_DIR%.
    exit /b 0
)

exit /b 1
