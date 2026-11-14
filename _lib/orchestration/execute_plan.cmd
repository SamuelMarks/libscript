@echo off
:: # execute_plan.cmd
:: ## Overview
:: Linear execution plan runner for LibScript multi-kernel and component builds on Windows.
:: ## Usage
:: execute_plan.cmd <path_to_execution_plan.json> [--dry-run]

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
    echo [ERROR] Missing required execution plan argument. 1>&2
    exit /b 1
)

set "PLAN_FILE=%~1"
set "DRY_RUN=0"
if /I "%~2"=="--dry-run" set "DRY_RUN=1"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"

if not exist "!PLAN_FILE!" (
    echo [ERROR] Execution plan file not found: !PLAN_FILE! 1>&2
    exit /b 1
)

call :ensure_jq
if errorlevel 1 (
    echo [ERROR] jq is required and could not be bootstrapped. 1>&2
    exit /b 1
)

set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
if not "%LIBSCRIPT_TARGET_SYSROOT%"=="" set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
set "STAMPS_DIR=!TARGET_SYSROOT!\var\lib\libscript\stamps"
if "!DRY_RUN!"=="0" (
    if not exist "!STAMPS_DIR!" mkdir "!STAMPS_DIR!"
)

for /f %%S in ('jq ".stages | length" "!PLAN_FILE!"') do set "TOTAL_STAGES=%%S"
set /a LAST_STAGE=!TOTAL_STAGES!-1

if !LAST_STAGE! GEQ 0 (
    for /L %%I in (0,1,!LAST_STAGE!) do (
        call :run_stage %%I || exit /b 1
    )
)

echo.
echo [SUCCESS] All execution plan stages processed successfully.
exit /b 0

:: ## show_help
:: Displays command-line usage instructions for execute_plan.cmd.
:show_help
echo Usage: %~nx0 ^<path_to_execution_plan.json^> [--dry-run]
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

:: ## run_stage
:: Executes all tasks within a single execution plan stage index.
:run_stage
set "S_IDX=%~1"
for /f "usebackq delims=" %%A in (`jq -r ".stages[!S_IDX!].stage" "!PLAN_FILE!"`) do set "STAGE_NAME=%%A"
echo.
echo [STAGE] === !STAGE_NAME! ===
for /f %%T in ('jq ".stages[!S_IDX!].tasks | length" "!PLAN_FILE!"') do set "TOTAL_TASKS=%%T"
set /a LAST_TASK=!TOTAL_TASKS!-1
if !LAST_TASK! LSS 0 exit /b 0
for /L %%K in (0,1,!LAST_TASK!) do (
    call :run_task !S_IDX! %%K || exit /b 1
)
exit /b 0

:: ## run_task
:: Executes or skips an individual task inside a stage with stamp idempotency.
:run_task
set "TS_IDX=%~1"
set "TT_IDX=%~2"
for /f "usebackq delims=" %%N in (`jq -r ".stages[!TS_IDX!].tasks[!TT_IDX!].name" "!PLAN_FILE!"`) do set "TASK_NAME=%%N"
for /f "usebackq delims=" %%C in (`jq -r ".stages[!TS_IDX!].tasks[!TT_IDX!].component" "!PLAN_FILE!"`) do set "TASK_COMP=%%C"
for /f "usebackq delims=" %%M in (`jq -r ".stages[!TS_IDX!].tasks[!TT_IDX!].action" "!PLAN_FILE!"`) do set "TASK_ACTION=%%M"
for /f "usebackq delims=" %%P in (`jq -r ".stages[!TS_IDX!].tasks[!TT_IDX!].stamp" "!PLAN_FILE!"`) do set "TASK_STAMP=%%P"
set "STAMP_FILE=!STAMPS_DIR!\!TASK_STAMP!"

if exist "!STAMP_FILE!" (
    echo [SKIP]  Task "!TASK_NAME!" ^(!TASK_ACTION!^) already satisfied by !TASK_STAMP!
    exit /b 0
)

echo [RUN]   Task "!TASK_NAME!" ^(!TASK_ACTION!^) [!TASK_COMP!]
if "!DRY_RUN!"=="1" (
    echo [DRYRUN] Would execute !TASK_ACTION! on !TASK_COMP! and touch !STAMP_FILE!
    exit /b 0
)

set "WIN_COMP=!TASK_COMP:/=\!"
set "EXEC_CMD=!LIBSCRIPT_ROOT_DIR!\!WIN_COMP!\setup.cmd"
if exist "!EXEC_CMD!" (
    set "EFFECTIVE_ACTION=!TASK_ACTION!"
    if /I "!EFFECTIVE_ACTION!"=="compile" set "EFFECTIVE_ACTION=install"
    if /I "!EFFECTIVE_ACTION!"=="bootstrap" set "EFFECTIVE_ACTION=install"
    set "STACK="
    set "LIBSCRIPT_TARGET_SYSROOT=!TARGET_SYSROOT!"
    set "LIBSCRIPT_STAGE=!STAGE_NAME!"
    call "!EXEC_CMD!" "!EFFECTIVE_ACTION!" || exit /b 1
) else (
    echo [INFO]  No leaf script !EXEC_CMD!; registering step completion
)
echo %DATE% %TIME%> "!STAMP_FILE!"
echo [OK]    Completed "!TASK_NAME!" -^> !TASK_STAMP!
exit /b 0
