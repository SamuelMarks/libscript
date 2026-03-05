@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "PURGE_DATA=0"
:parse_args
if "%~1"=="" goto after_parse
if /i "%~1"=="--purge-data" set "PURGE_DATA=1"
shift
goto parse_args
:after_parse

if not "%FLUENTBIT_SERVICE_NAME%"=="" (
    sc stop %FLUENTBIT_SERVICE_NAME% >nul 2>&1
    sc delete %FLUENTBIT_SERVICE_NAME% >nul 2>&1
) else (
    sc stop libscript_fluentbit >nul 2>&1
    sc delete libscript_fluentbit >nul 2>&1
)

where choco >nul 2>&1
if %ERRORLEVEL% equ 0 choco uninstall fluent-bit -y >nul 2>&1

:: Default uninstall hook for Windows native installation
if "%INSTALLED_DIR%"=="" set "INSTALLED_DIR=%LIBSCRIPT_ROOT_DIR%\installed\fluent-bit"

if not "%INSTALLED_DIR%"=="" (
    if exist "%INSTALLED_DIR%" (
        echo Removing %INSTALLED_DIR%...
        rmdir /s /q "%INSTALLED_DIR%"
    ) else (
        echo No local installation directory found for fluent-bit at %INSTALLED_DIR%.
    )
)

if "!PURGE_DATA!"=="1" (
    echo Purging fluent-bit data...
    if exist "%LIBSCRIPT_ROOT_DIR%\data\fluentbit" (
        rmdir /s /q "%LIBSCRIPT_ROOT_DIR%\data\fluentbit"
    )
)

exit /b 0