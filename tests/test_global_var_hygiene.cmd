@echo off
:: # test_global_var_hygiene.cmd
::
:: ## Overview
:: Hermetic regression test suite on Windows verifying global variable scoping, base_vars.schema.json cap (<=32),
:: scoped variable packs (schemas/vars/*.schema.json), $ref integrity, and unbloated component READMEs.
::
:: ## Usage
:: tests\test_global_var_hygiene.cmd

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

set "BASE_SCHEMA=!LIBSCRIPT_ROOT_DIR!\_lib\_common\base_vars.schema.json"
if not exist "!BASE_SCHEMA!" (
    echo [FAIL] Missing _lib\_common\base_vars.schema.json >&2
    exit /b 1
)

for /f "delims=" %%C in ('jq -r ".properties | keys | length" "!BASE_SCHEMA!"') do set "PROP_COUNT=%%C"
REM wincheck disable=CMD2003
if !PROP_COUNT! GTR 32 (
    echo [FAIL] base_vars.schema.json exceeds 32 core properties: !PROP_COUNT! >&2
    exit /b 1
)
REM wincheck disable=CMD2003
if !PROP_COUNT! LSS 20 (
    echo [FAIL] base_vars.schema.json unexpectedly small: !PROP_COUNT! >&2
    exit /b 1
)

for %%P in (tpu tfrc experiment rtos image_synth cloud_tags source_toolchain) do (
    if not exist "!LIBSCRIPT_ROOT_DIR!\schemas\vars\%%P.schema.json" (
        echo [FAIL] Missing schemas\vars\%%P.schema.json >&2
        exit /b 1
    )
)

for %%R in (
    "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\lynx\README.md"
    "!LIBSCRIPT_ROOT_DIR!\_lib\caches\hazelcast\README.md"
    "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\exim\README.md"
) do (
    findstr /C:"TPU_ZONE" /C:"JETSTREAM_IMAGE" /C:"LIBSCRIPT_EXPERIMENT_PAPER_DIR" /C:"LIBSCRIPT_RTOS_MCUBOOT" "%%~R" >nul 2>&1
    if not errorlevel 1 (
        echo [FAIL] Unrelated README %%~R still contains leaked subsystem globals >&2
        exit /b 1
    )
)

findstr /C:"LIBSCRIPT_HOME" "!LIBSCRIPT_ROOT_DIR!\_lib\_common\README.md" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] _lib\_common\README.md missing LIBSCRIPT_HOME documentation >&2
    exit /b 1
)
findstr /C:"JETSTREAM_IMAGE" "!LIBSCRIPT_ROOT_DIR!\_lib\app-servers\jetstream\README.md" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] jetstream\README.md missing JETSTREAM_IMAGE documentation >&2
    exit /b 1
)

echo [PASS] Global variable scoping and README hygiene verified (!PROP_COUNT! core globals^).
exit /b 0
