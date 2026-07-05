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

for %%I in ("%~dp0..\..") do set "COMP_DIR=%%~fI"
for %%I in ("%COMP_DIR%") do set "COMPONENT_NAME=%%~nxI"

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
