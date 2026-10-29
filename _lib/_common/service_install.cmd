@echo off
:: # service_install.cmd
::
:: ## Overview
:: Internal script for service_install on Windows. Registers, overrides environment variables for,
:: or removes a Windows service or fallback runner, respecting LIBSCRIPT_INIT_SYSTEM.
::
:: ## Usage
:: service_install.cmd <install|uninstall|override-env> <service_name> [args...]

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
if /i "%~1"=="install" (
    call :libscript_install_service "%~2" "%~3" "%~4" "%~5" "%~6"
    exit /b !ERRORLEVEL!
)
if /i "%~1"=="--install" (
    call :libscript_install_service "%~2" "%~3" "%~4" "%~5" "%~6"
    exit /b !ERRORLEVEL!
)

if /i "%~5"=="uninstall" (
    call :libscript_uninstall_service "%~1"
    exit /b !ERRORLEVEL!
)

call :libscript_install_service "%~1" "%~2" "%~3" "%~4" "%~5"
exit /b !ERRORLEVEL!

:: ## libscript_install_service
:: Generates a service runner script and registers a Windows service (or fallback daemon).
:libscript_install_service
set "_SERVICE_NAME=%~1"
set "_EXEC_START=%~2"
set "_WORKING_DIR=%~3"
set "_DESCRIPTION=%~4"
set "_ENV_VARS=%~5"

if "!_SERVICE_NAME!"=="" (
    echo Usage: %0 [SERVICE_NAME] [EXEC_START] [WORKING_DIR] [DESCRIPTION]
    exit /b 1
)
if "!_WORKING_DIR!"=="" set "_WORKING_DIR=%CD%"
if "!_DESCRIPTION!"=="" set "_DESCRIPTION=!_SERVICE_NAME! service"

set "_DATA_BASE=%TEMP%\data"
if defined LIBSCRIPT_DATA_DIR set "_DATA_BASE=!LIBSCRIPT_DATA_DIR!"
if not exist "!_DATA_BASE!" mkdir "!_DATA_BASE!"
set "_SVC_DIR=!_DATA_BASE!\!_SERVICE_NAME!"
if not exist "!_SVC_DIR!" mkdir "!_SVC_DIR!"
set "_RUNNER_FILE=!_SVC_DIR!\run_!_SERVICE_NAME!.cmd"
set "_LOG_FILE=!_SVC_DIR!\service.log"
set "_MANIFEST_DIR=%LIBSCRIPT_SERVICE_MANIFEST_DIR%"
if "!_MANIFEST_DIR!"=="" set "_MANIFEST_DIR=!_WORKING_DIR!"

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\python_env.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\python_env.cmd" libscript_python_ensure_venv_owner "!_WORKING_DIR!" "%PYTHON_VERSION%"
)

for %%B in ("!_WORKING_DIR!\.venv\Scripts" "!_WORKING_DIR!\node_modules\.bin" "!_MANIFEST_DIR!\.venv\Scripts" "!_MANIFEST_DIR!\node_modules\.bin") do (
    if exist "%%~fB" (
        echo ";!PATH!;" | findstr /I /C:";%%~fB;" >nul 2>&1
        if errorlevel 1 set "PATH=%%~fB;!PATH!"
    )
)

(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo set "PATH=!PATH!"
    if exist "!_SVC_DIR!\.env.service" (
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!_SVC_DIR!\.env.service"^) do set "%%%%L"
    )
    if exist "!_MANIFEST_DIR!\.env.libscript" (
        echo for /f "usebackq tokens=* delims=" %%%%L in ^("!_MANIFEST_DIR!\.env.libscript"^) do set "%%%%L"
        echo if defined SERVICE_PATH set "PATH=%%SERVICE_PATH%%;!PATH!"
        echo if defined SERVICE_EXTRA_PATH set "PATH=%%SERVICE_EXTRA_PATH%%;!PATH!"
    )
) > "!_RUNNER_FILE!"

if defined LIBSCRIPT_SERVICE_ENV_FILES (
    for %%F in ("!LIBSCRIPT_SERVICE_ENV_FILES:;=" "!") do (
        set "_EF_ITEM=%%~F"
        if not "!_EF_ITEM!"=="" (
            set "_EF_WIN=!_EF_ITEM:/=\!"
            if exist "!_WORKING_DIR!\!_EF_WIN!" (
                echo for /f "usebackq tokens=* delims=" %%%%L in ^("!_WORKING_DIR!\!_EF_WIN!"^) do set "%%%%L" >> "!_RUNNER_FILE!"
            ) else if exist "!_MANIFEST_DIR!\!_EF_WIN!" (
                echo for /f "usebackq tokens=* delims=" %%%%L in ^("!_MANIFEST_DIR!\!_EF_WIN!"^) do set "%%%%L" >> "!_RUNNER_FILE!"
            ) else if exist "!_EF_WIN!" (
                echo for /f "usebackq tokens=* delims=" %%%%L in ^("!_EF_WIN!"^) do set "%%%%L" >> "!_RUNNER_FILE!"
            )
        )
    )
)

if defined LIBSCRIPT_SERVICE_ENV_JSON (
    for /f "delims=" %%e in ('echo !LIBSCRIPT_SERVICE_ENV_JSON! ^| jq -r "(.env // {}) | to_entries[]? | \"set \\\"\(.key)=\(.value)\\\"\"" 2^>nul') do (
        echo %%e >> "!_RUNNER_FILE!"
    )
)

for %%B in ("!_MANIFEST_DIR!\node_modules\.bin" "!_MANIFEST_DIR!\.venv\Scripts" "!_WORKING_DIR!\node_modules\.bin" "!_WORKING_DIR!\.venv\Scripts") do (
    if exist "%%~fB" (
        echo echo ";%%PATH%%;" ^| findstr /I /C:";%%~fB;" ^>nul 2^>^&1 ^|^| set "PATH=%%~fB;%%PATH%%" >> "!_RUNNER_FILE!"
    )
)

(
    echo pushd "!_WORKING_DIR!"
    echo call !_EXEC_START! ^>^> "!_LOG_FILE!" 2^>^&1
    echo popd
) >> "!_RUNNER_FILE!"

set "_INIT_SYS=%LIBSCRIPT_INIT_SYSTEM%"
if "!_INIT_SYS!"=="" set "_INIT_SYS=%INIT_SYSTEM%"
if "%LIBSCRIPT_FORCE_FALLBACK_DAEMON%"=="1" set "_INIT_SYS=fallback"
if /i "!_INIT_SYS!"=="fallback" (
    echo [INFO] Registered fallback daemon runner for service: !_SERVICE_NAME! ^(!_RUNNER_FILE!^)
    exit /b 0
)
if /i "!_INIT_SYS!"=="none" (
    echo [INFO] Registered fallback daemon runner for service: !_SERVICE_NAME! ^(!_RUNNER_FILE!^)
    exit /b 0
)

sc.exe query "!_SERVICE_NAME!" >nul 2>&1
if not errorlevel 1 (
    echo [INFO] [DAEMON] [UPDATE] Updated Windows service unit for '!_SERVICE_NAME!' ^(!_RUNNER_FILE!^).
    sc.exe config "!_SERVICE_NAME!" binPath= "cmd.exe /c \"!_RUNNER_FILE!\"" start= auto obj= LocalSystem >nul 2>&1
) else (
    set "_NSSM_BIN="
    where nssm >nul 2>&1
    if not errorlevel 1 set "_NSSM_BIN=nssm"
    if "!_NSSM_BIN!"=="" if exist "%USERPROFILE%\.libscript\nssm\latest\bin\nssm.exe" set "_NSSM_BIN=%USERPROFILE%\.libscript\nssm\latest\bin\nssm.exe"
    if not "!_NSSM_BIN!"=="" (
        echo [INFO] [DAEMON] [CREATE] Installed Windows service unit via NSSM for '!_SERVICE_NAME!' ^(!_RUNNER_FILE!^).
        "!_NSSM_BIN!" install "!_SERVICE_NAME!" "%ComSpec%" "/c \"!_RUNNER_FILE!\"" >nul 2>&1
        "!_NSSM_BIN!" set "!_SERVICE_NAME!" AppDirectory "!_WORKING_DIR!" >nul 2>&1
        "!_NSSM_BIN!" set "!_SERVICE_NAME!" AppStdout "!_LOG_FILE!" >nul 2>&1
        "!_NSSM_BIN!" set "!_SERVICE_NAME!" AppStderr "!_LOG_FILE!" >nul 2>&1
    ) else (
        echo [INFO] [DAEMON] [CREATE] Installed Windows service unit for '!_SERVICE_NAME!' ^(!_RUNNER_FILE!^).
        sc.exe create "!_SERVICE_NAME!" binPath= "cmd.exe /c \"!_RUNNER_FILE!\"" start= auto obj= LocalSystem >nul 2>&1
    )
)
sc.exe description "!_SERVICE_NAME!" "!_DESCRIPTION!" >nul 2>&1
set "_SVC_REG_ENV=PATH=!PATH!\0SERVICE_PATH=!PATH!"
if exist "!_MANIFEST_DIR!\.env.libscript" (
    for /f "usebackq tokens=1* delims==" %%A in ("!_MANIFEST_DIR!\.env.libscript") do (
        if not "%%A"=="" (
            set "_rk=%%A"
            if not "!_rk:~0,1!"=="#" set "_SVC_REG_ENV=!_SVC_REG_ENV!\0%%A=%%B"
        )
    )
)
reg query "HKLM\SYSTEM\CurrentControlSet\Services\!_SERVICE_NAME!" >nul 2>&1
if not errorlevel 1 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\!_SERVICE_NAME!" /v Environment /t REG_MULTI_SZ /d "!_SVC_REG_ENV!" /f >nul 2>&1
)
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
for %%K in ("%~2" "%~3" "%~4" "%~5") do (
    set "_KV=%%~K"
    if not "!_KV!"=="" (
        for /f "tokens=1* delims==" %%A in ("!_KV!") do (
            if exist "!_ENV_FILE!" (
                findstr /v /b /c:"%%A=" "!_ENV_FILE!" > "!_ENV_FILE!.tmp" 2>nul
                move /y "!_ENV_FILE!.tmp" "!_ENV_FILE!" >nul 2>&1
            )
            echo !_KV!>> "!_ENV_FILE!"
            setx %%A "%%B" /M >nul 2>&1
        )
    )
)
set "_REG_MULTI=PATH=!PATH!\0SERVICE_PATH=!PATH!"
if exist "!_ENV_FILE!" (
    for /f "usebackq tokens=* delims=" %%L in ("!_ENV_FILE!") do (
        if not "%%L"=="" set "_REG_MULTI=!_REG_MULTI!\0%%L"
    )
)
reg query "HKLM\SYSTEM\CurrentControlSet\Services\!_OVR_SVC!" >nul 2>&1
if not errorlevel 1 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\!_OVR_SVC!" /v Environment /t REG_MULTI_SZ /d "!_REG_MULTI!" /f >nul 2>&1
)
echo [INFO] [DAEMON] [OVERRIDE] Configured environment overrides for '!_OVR_SVC!' in !_ENV_FILE! and Windows Service Registry.
exit /b 0
