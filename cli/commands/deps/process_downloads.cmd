@echo off
:: # process_downloads.cmd
::
:: ## Overview
:: Manages downloading and verification of external resources and assets from a file list on Windows.
:: 
:: ## Usage
:: process_downloads.cmd <list_file>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\.."
)

set "list_file=%~1"
if "%list_file%"=="" (
    echo Usage: %~nx0 ^<list_file^> 1>&2
    exit /b 1
)
if not exist "%list_file%" (
    echo Error: File not found: %list_file% 1>&2
    exit /b 1
)

for /f "usebackq tokens=1,2,3 delims= " %%A in ("%list_file%") do (
    set "u=%%A"
    set "d=%%B"
    set "c=%%C"
    if not "!u!"=="" (
        if not "!u:~0,1!"=="#" (
            call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!u!" "!d!" "!c!"
        )
    )
)
exit /b 0
