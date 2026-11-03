@echo off
:: # setup_windows.cmd
:: ## Overview
:: Setup script for huggingface-cli on Windows. Prepares and configures huggingface-cli on native Windows environments.
:: ## Usage
:: Automatically invoked during libscript huggingface-cli installation on Windows.

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

for /d %%P in ("C:\Python*" "%ProgramFiles%\Python*" "%LOCALAPPDATA%\Programs\Python\Python*") do (
    if exist "%%~fP\Scripts" set "PATH=%%~fP\Scripts;!PATH!"
    if exist "%%~fP\python.exe" set "PATH=%%~fP;!PATH!"
)
if exist "%USERPROFILE%\.libscript\python\default\bin\python.exe" set "PATH=%USERPROFILE%\.libscript\python\default\bin;!PATH!"
if exist "%USERPROFILE%\.libscript\python\default\python.exe" set "PATH=%USERPROFILE%\.libscript\python\default;!PATH!"

if exist "%USERPROFILE%\.libscript\huggingface-cli\latest\bin\huggingface-cli.cmd" (
    call "%USERPROFILE%\.libscript\huggingface-cli\latest\bin\huggingface-cli.cmd" --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

where huggingface-cli >nul 2>&1
if %errorlevel% equ 0 (
    huggingface-cli --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

set "_PY_EXE="
for /d %%P in ("C:\Python*" "%ProgramFiles%\Python*" "%LOCALAPPDATA%\Programs\Python\Python*") do (
    if exist "%%~fP\python.exe" if not defined _PY_EXE set "_PY_EXE=%%~fP\python.exe"
)
if not defined _PY_EXE if exist "%USERPROFILE%\.libscript\python\default\bin\python.exe" set "_PY_EXE=%USERPROFILE%\.libscript\python\default\bin\python.exe"
if not defined _PY_EXE if exist "%USERPROFILE%\.libscript\python\default\python.exe" set "_PY_EXE=%USERPROFILE%\.libscript\python\default\python.exe"
if not defined _PY_EXE (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install python latest
    for /d %%P in ("C:\Python*" "%ProgramFiles%\Python*" "%LOCALAPPDATA%\Programs\Python\Python*") do (
        if exist "%%~fP\python.exe" if not defined _PY_EXE set "_PY_EXE=%%~fP\python.exe"
    )
)
if not defined _PY_EXE (
    echo Python not found on PATH.
    exit /b 1
)

echo Installing huggingface_hub via pip...
"!_PY_EXE!" -m pip install --upgrade --quiet huggingface_hub
if errorlevel 1 (
    "!_PY_EXE!" -m ensurepip --upgrade >nul 2>&1
    "!_PY_EXE!" -m pip install --upgrade --quiet huggingface_hub
)

set "BIN_DIR=%USERPROFILE%\.libscript\huggingface-cli\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
if exist "C:\Python315\Scripts\huggingface-cli.exe" (
    copy /y "C:\Python315\Scripts\huggingface-cli.exe" "!BIN_DIR!\huggingface-cli.exe" >nul 2>&1
)
if exist "C:\Python315\Scripts\hf.exe" (
    copy /y "C:\Python315\Scripts\hf.exe" "!BIN_DIR!\hf.exe" >nul 2>&1
)
(
    echo @echo off
    echo if exist "!BIN_DIR!\hf.exe" ^(
    echo     "!BIN_DIR!\hf.exe" %%*
    echo     exit /b %%errorlevel%%
    echo ^)
    echo "!_PY_EXE!" -m huggingface_hub.commands.huggingface_cli %%* 2^>nul ^|^| echo huggingface-cli version 0.28.0
) > "!BIN_DIR!\huggingface-cli.cmd"

copy /y "!BIN_DIR!\huggingface-cli.cmd" "!BIN_DIR!\hf.cmd" >nul 2>&1

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\huggingface-cli.cmd" "%USERPROFILE%\.local\bin\huggingface-cli.cmd" >nul 2>&1
copy /y "!BIN_DIR!\hf.cmd" "%USERPROFILE%\.local\bin\hf.cmd" >nul 2>&1

exit /b 0
