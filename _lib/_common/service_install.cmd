@echo off
setlocal EnableDelayedExpansion

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

:: Delegate to PowerShell service_install.ps1
powershell -ExecutionPolicy Bypass -File "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.ps1" %*
exit /b %errorlevel%
