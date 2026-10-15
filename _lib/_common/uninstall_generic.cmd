@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Provides fallback uninstallation logic for components on Windows.
:: It handles delegating to third-party managers like mise/vfox,
:: or safely removing the isolated native installation directories.
::
:: ## Usage
:: Typically called internally by uninstall.cmd.

setlocal EnableDelayedExpansion
set "CALLER_FILE=%THIS_FILE%"
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

set "COMPONENT_NAME=%PACKAGE_NAME%"
if "%COMPONENT_NAME%"=="" if not "%CALLER_FILE%"=="" (
    for %%I in ("%CALLER_FILE%\..") do set "COMP_DIR=%%~fI"
    for %%I in ("!COMP_DIR!") do set "COMPONENT_NAME=%%~nxI"
)
if "%COMPONENT_NAME%"=="" (
    for %%I in ("%CD%") do set "COMPONENT_NAME=%%~nxI"
)

:: Very basic placeholder logic for Windows native uninstall
if not "%VERSION%"=="" (
    if not "%VERSION%"=="latest" (
        if not "%VERSION%"=="lts" (
            if not "%VERSION%"=="stable" (
                set "TARGET_DIR=%LIBSCRIPT_HOME%\%COMPONENT_NAME%\%VERSION%"
                if "%LIBSCRIPT_HOME%"=="" set "TARGET_DIR=%USERPROFILE%\.libscript\%COMPONENT_NAME%\%VERSION%"
                
                if exist "!TARGET_DIR!" (
                    echo Removing !TARGET_DIR!...
                    rmdir /s /q "!TARGET_DIR!"
                ) else (
                    echo %COMPONENT_NAME% version %VERSION% is not installed natively at !TARGET_DIR!.
                )
            )
        )
    )
) else (
    set "TARGET_DIR=%LIBSCRIPT_HOME%\%COMPONENT_NAME%"
    if "%LIBSCRIPT_HOME%"=="" set "TARGET_DIR=%USERPROFILE%\.libscript\%COMPONENT_NAME%"
    echo Removing all native installations of %COMPONENT_NAME%...
    if exist "!TARGET_DIR!" rmdir /s /q "!TARGET_DIR!"
)

endlocal
