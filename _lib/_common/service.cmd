@echo off
setlocal EnableDelayedExpansion
:: # LibScript Service Management Module (Windows Batch)
::
:: ## Overview
:: This module provides operations to start, stop, and manage Windows services.
::
:: ## Usage
:: ```batch
:: call "%LIBSCRIPT_ROOT_DIR%\\_lib\\_common\\service.cmd" :libscript_service start <service_name>
:: ```


if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%~dp0"
    :find_root
    if exist "!d!\ROOT" (set "LIBSCRIPT_ROOT_DIR=!d!") else (
        for %%P in ("!d!") do set "parent=%%~dpP"
        set "d=!parent:~0,-1!"
        if "!d!"=="" (
            echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
            exit /b 1
        )
        goto :find_root
    )
)

:: Delegate to PowerShell service.ps1
powershell -ExecutionPolicy Bypass -File "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.ps1" %*
exit /b %errorlevel%
