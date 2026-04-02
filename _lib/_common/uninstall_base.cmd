@echo off
:: # LibScript Common Uninstall Entrypoint (Windows Batch)
::
:: ## Overview
:: Standardized entrypoint for component uninstallation on Windows.
:: Resolves root, checks privileges, and delegates to uninstall scripts.
::
:: ## Usage
:: Your component's `uninstall.cmd` should call this.
::
:: ```batch
:: @echo off
:: call "%~dp0\..\..\..\_lib\_common\uninstall_base.cmd"
:: ```

setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve LIBSCRIPT_ROOT_DIR
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

:: Privilege Check
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :check_admin
if errorlevel 1 (
    echo [INFO] Elevating to administrator...
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\priv.cmd" :priv "%~f0"
    exit /b %errorlevel%
)

:: Delegate to PowerShell if uninstall_win.ps1 or uninstall.ps1 exists
if exist "%SCRIPT_DIR%\uninstall_win.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%SCRIPT_DIR%\uninstall_win.ps1' }"
    exit /b !errorlevel!
) else if exist "%SCRIPT_DIR%\uninstall.ps1" (
    set "COMMON_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\_common"
    powershell -ExecutionPolicy Bypass -Command "& { . '!COMMON_DIR!\log.ps1'; . '!COMMON_DIR!\pkg_mgr.ps1'; . '!COMMON_DIR!\service.ps1'; & '%SCRIPT_DIR%\uninstall.ps1' }"
    exit /b !errorlevel!
) else (
    echo [INFO] No uninstall PowerShell script found in %SCRIPT_DIR%.
)
