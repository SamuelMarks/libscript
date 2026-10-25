@echo off
:: # service_install.cmd
::
:: ## Overview
:: Internal script for service_install on Windows. Registers, overrides environment variables for,
:: or removes a Windows service or fallback runner.
::
:: ## Usage
:: service_install.cmd <install|uninstall|override-env> <service_name> [args...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if /i "%~1"=="--uninstall" (
    call :libscript_uninstall_service "%~2"
    exit /b !ERRORLEVEL!
)
if /i "%~1"=="uninstall" (
    call :libscript_uninstall_service "%~2"
    exit /b !ERRORLEVEL!
)
if /i "%~1"==":libscript_uninstall_service" (
    call :libscript_uninstall_service "%~2"
    exit /b !ERRORLEVEL!
)
if /i "%~1"=="override-env" (
    call :libscript_service_override_env "%~2" "%~3" "%~4" "%~5" "%~6"
    exit /b !ERRORLEVEL!
)
if /i "%~1"=="--override-env" (
    call :libscript_service_override_env "%~2" "%~3" "%~4" "%~5" "%~6"
    exit /b !ERRORLEVEL!
)
if /i "%~1"==":libscript_service_override_env" (
    call :libscript_service_override_env "%~2" "%~3" "%~4" "%~5" "%~6"
    exit /b !ERRORLEVEL!
)

set "_SERVICE_NAME=%~1"
set "_EXEC_START=%~2"
set "_WORKING_DIR=%~3"
set "_DESCRIPTION=%~4"

if "%_SERVICE_NAME%"=="" (
    echo Usage: %0 [SERVICE_NAME] [EXEC_START] [WORKING_DIR] [DESCRIPTION]
    exit /b 1
)

if /i "%~5"=="uninstall" (
    call :libscript_uninstall_service "%_SERVICE_NAME%"
    exit /b !ERRORLEVEL!
)

if "%_DESCRIPTION%"=="" set "_DESCRIPTION=%_SERVICE_NAME% service"

echo Installing Windows service: %_SERVICE_NAME%
sc.exe create "%_SERVICE_NAME%" binPath= "%_EXEC_START%" start= auto obj= LocalSystem
sc.exe description "%_SERVICE_NAME%" "%_DESCRIPTION%"
exit /b 0

:: ## libscript_uninstall_service
:: Stops and deletes a Windows service and cleans up any fallback PID/runner files.
:libscript_uninstall_service
set "_UN_SVC=%~1"
if "!_UN_SVC!"=="" exit /b 1
echo Uninstalling Windows service: !_UN_SVC!
sc.exe stop "!_UN_SVC!" >nul 2>&1
sc.exe delete "!_UN_SVC!" >nul 2>&1
taskkill /fi "WINDOWTITLE eq !_UN_SVC!" /f >nul 2>&1
set "_DATA_BASE=%TEMP%\data"
if defined LIBSCRIPT_DATA_DIR set "_DATA_BASE=!LIBSCRIPT_DATA_DIR!"
if exist "!_DATA_BASE!\!_UN_SVC!\service.pid" del /f /q "!_DATA_BASE!\!_UN_SVC!\service.pid" >nul 2>&1
if exist "!_DATA_BASE!\!_UN_SVC!\run_!_UN_SVC!.cmd" del /f /q "!_DATA_BASE!\!_UN_SVC!\run_!_UN_SVC!.cmd" >nul 2>&1
exit /b 0

:: ## libscript_service_override_env
:: Persists environment variable overrides for a Windows service in the Registry and fallback .env.service file.
:libscript_service_override_env
set "_OVR_SVC=%~1"
if "!_OVR_SVC!"=="" (
    echo [ERROR] Usage: service_install.cmd override-env ^<service_name^> ^<KEY=VALUE...^> >&2
    exit /b 1
)
set "_DATA_BASE=%TEMP%\data"
if defined LIBSCRIPT_DATA_DIR set "_DATA_BASE=!LIBSCRIPT_DATA_DIR!"
if not exist "!_DATA_BASE!\!_OVR_SVC!" mkdir "!_DATA_BASE!\!_OVR_SVC!"
set "_ENV_FILE=!_DATA_BASE!\!_OVR_SVC!\.env.service"
type nul > "!_ENV_FILE!"
set "_REG_MULTI="
for %%K in ("%~2" "%~3" "%~4" "%~5") do (
    set "_KV=%%~K"
    if not "!_KV!"=="" (
        echo !_KV!>> "!_ENV_FILE!"
        for /f "tokens=1* delims==" %%A in ("!_KV!") do (
            setx %%A "%%B" /M >nul 2>&1
        )
        if defined _REG_MULTI (
            set "_REG_MULTI=!_REG_MULTI!\0!_KV!"
        ) else (
            set "_REG_MULTI=!_KV!"
        )
    )
)
reg query "HKLM\SYSTEM\CurrentControlSet\Services\!_OVR_SVC!" >nul 2>&1
if not errorlevel 1 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\!_OVR_SVC!" /v Environment /t REG_MULTI_SZ /d "!_REG_MULTI!" /f >nul 2>&1
)
exit /b 0
