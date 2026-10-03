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
:: Translates Windows MSI location variables into absolute paths on Windows.
::
:: ## Usage
::   call resolve_location.cmd "[ProgramFiles64Folder]LibScript\MySQL"

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

set "INPUT=%~1"
if "%INPUT%"=="" (
    echo Usage: %0 ^<path_with_variables^> >&2
    exit /b 1
)

:: Replace forward slashes with backslashes
set "OUTPUT=!INPUT:/=\!"

:: Resolve based on standard msi-rs abstractions
if defined ProgramW6432 (
    set "OUTPUT=!OUTPUT:[ProgramFiles64Folder]=%ProgramW6432%\!"
) else (
    set "OUTPUT=!OUTPUT:[ProgramFiles64Folder]=%ProgramFiles%\!"
)
set "OUTPUT=!OUTPUT:[ProgramFilesFolder]=%ProgramFiles%\!"
set "OUTPUT=!OUTPUT:[CommonAppDataFolder]=%ProgramData%\!"
set "OUTPUT=!OUTPUT:[AppDataFolder]=%APPDATA%\!"
set "OUTPUT=!OUTPUT:[LocalAppDataFolder]=%LOCALAPPDATA%\!"

:: Clean up any double backslashes
set "OUTPUT=!OUTPUT:\\=\!"

echo !OUTPUT!
exit /b 0
