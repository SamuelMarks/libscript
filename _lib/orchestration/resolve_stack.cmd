@echo off
:: # resolve_stack.cmd
:: ## Overview
:: Portable dependency resolver and multi-kernel execution plan generator using jq on Windows.
:: ## Usage
:: resolve_stack.cmd <path_to_config.json> [output_plan.json]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

if "%~1"=="" (
    echo [ERROR] Missing required configuration file argument. 1>&2
    exit /b 1
)

set "CONFIG_FILE=%~1"
set "OUTPUT_FILE=%~2"
set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"
set "LIB_DIR=!REPO_ROOT!\_lib"

if not exist "!CONFIG_FILE!" (
    echo [ERROR] Configuration file does not exist: !CONFIG_FILE! 1>&2
    exit /b 1
)

call :ensure_jq
if errorlevel 1 (
    echo [ERROR] jq is required and could not be bootstrapped. 1>&2
    exit /b 1
)

set "TARGET_OS=windows"
if not "%LIBSCRIPT_TARGET_OS%"=="" set "TARGET_OS=%LIBSCRIPT_TARGET_OS%"

jq -e "." "!CONFIG_FILE!" >nul 2>nul
if errorlevel 1 (
    if "!OUTPUT_FILE!"=="" (
        echo {"selected": [], "conflicts": [], "provided": [], "ports": []}
    ) else (
        for %%P in ("!OUTPUT_FILE!") do set "OUT_DIR=%%~dpP"
        if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
        echo {"selected": [], "conflicts": [], "provided": [], "ports": []}> "!OUTPUT_FILE!"
    )
    exit /b 0
)

set "CACHE_DIR=!REPO_ROOT!\cache"
if not "%LIBSCRIPT_CACHE_DIR%"=="" set "CACHE_DIR=%LIBSCRIPT_CACHE_DIR%"
if not exist "!CACHE_DIR!" mkdir "!CACHE_DIR!" >nul 2>&1
set "CATALOG_JSON=!CACHE_DIR!\manifests_catalog_v2.json"
set "CATALOG_META=!CACHE_DIR!\manifests_catalog_v2.meta"
set "_MF_SIG=0"
for /R "!LIB_DIR!" %%F in (manifest.json) do set /a _MF_SIG+=1

set "_USE_CACHE=0"
if exist "!CATALOG_JSON!" if exist "!CATALOG_META!" (
    set /p _CACHED_SIG=<"!CATALOG_META!"
    if "!_CACHED_SIG!"=="!_MF_SIG!" set "_USE_CACHE=1"
)

if "!_USE_CACHE!"=="1" (
    set "TMP_ARR=!CATALOG_JSON!"
) else (
    set "TMP_RAW=%TEMP%\libscript_manifests_raw_%RANDOM%.jsonl"
    set "TMP_ARR=!CATALOG_JSON!"
    if exist "!TMP_RAW!" del /f /q "!TMP_RAW!" >nul 2>&1
    for /R "!LIB_DIR!" %%F in (manifest.json) do (
        jq "{ _manifest_dir: (input_filename | gsub(\"\\\\\"; \"/\") | sub(\"^.*/_lib/\"; \"_lib/\") | sub(\"/manifest\\.json$\"; \"\")) } + ." "%%F" >> "!TMP_RAW!" 2>nul
    )
    if exist "!TMP_RAW!" (
        jq -s "." "!TMP_RAW!" > "!TMP_ARR!" 2>nul
        del /f /q "!TMP_RAW!" >nul 2>&1
        echo !_MF_SIG!>"!CATALOG_META!"
    ) else (
        echo []> "!TMP_ARR!"
    )
)

if "!OUTPUT_FILE!"=="" (
    jq --arg target_os "!TARGET_OS!" --slurpfile manifests "!TMP_ARR!" -n "{config: input, manifests: ($manifests[0] // [])}" "!CONFIG_FILE!" | jq -L "!REPO_ROOT!\_lib\utilities" -L "!SCRIPT_DIR!" --arg target_os "!TARGET_OS!" -r -f "!SCRIPT_DIR!\resolve_stack.jq"
) else (
    for %%P in ("!OUTPUT_FILE!") do set "OUT_DIR=%%~dpP"
    if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
    jq --arg target_os "!TARGET_OS!" --slurpfile manifests "!TMP_ARR!" -n "{config: input, manifests: ($manifests[0] // [])}" "!CONFIG_FILE!" | jq -L "!REPO_ROOT!\_lib\utilities" -L "!SCRIPT_DIR!" --arg target_os "!TARGET_OS!" -r -f "!SCRIPT_DIR!\resolve_stack.jq" > "!OUTPUT_FILE!"
    echo [INFO] Execution plan generated at !OUTPUT_FILE!
)
exit /b 0

:: ## show_help
:: Displays command-line usage instructions for resolve_stack.cmd.
:show_help
echo Usage: %~nx0 ^<path_to_config.json^> [output_plan.json]
echo Resolves component dependencies and emits an execution plan.
exit /b 0

:: ## ensure_jq
:: Bootstraps _lib\utilities\jq when jq is not already available on PATH.
:ensure_jq
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest >nul 2>&1
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
where jq >nul 2>&1
exit /b !ERRORLEVEL!
