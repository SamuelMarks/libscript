@echo off
:: # execute_plan.cmd
::
:: ## Overview
:: Linear execution plan runner for LibScript builds on Windows.
:: Reads a deterministic execution-plan.json, iterates over stages and tasks,
:: checks and updates idempotency stage stamp files, and orchestrates task executions.
::
:: ## Usage
:: Run `execute_plan.cmd <path_to_execution_plan.json> [--dry-run]` to process tasks sequentially.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 ^<path_to_execution_plan.json^> [--dry-run]
    echo Executes a linear build execution plan step-by-step with stamp tracking.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<path_to_execution_plan.json^> [--dry-run]
    echo Executes a linear build execution plan step-by-step with stamp tracking.
    exit /b 0
)

if "%~1"=="" (
    echo [ERROR] Missing required execution plan argument.
    echo Usage: %~nx0 ^<path_to_execution_plan.json^> [--dry-run]
    exit /b 1
)

set "PLAN_FILE=%~1"
set "DRY_RUN=0"
if "%~2"=="--dry-run" set "DRY_RUN=1"

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\.."

if not exist "%PLAN_FILE%" (
    echo [ERROR] Execution plan file not found: %PLAN_FILE%
    exit /b 1
)

where jq >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] jq is required but not installed.
    exit /b 1
)

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    set "TARGET_SYSROOT=%REPO_ROOT%\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%TARGET_SYSROOT%\var\lib\libscript\stamps"
if "%DRY_RUN%"=="0" (
    if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"
)

for /f %%S in ('jq ".stages | length" "%PLAN_FILE%"') do set "TOTAL_STAGES=%%S"
set "STAGE_IDX=0"

:stage_loop
if !STAGE_IDX! geq !TOTAL_STAGES! goto all_done

for /f "delims=" %%N in ('jq -r ".stages[!STAGE_IDX!].stage" "%PLAN_FILE%"') do set "STAGE_NAME=%%N"
for /f "delims=" %%D in ('jq -r ".stages[!STAGE_IDX!].description // """ "%PLAN_FILE%"') do set "STAGE_DESC=%%D"

echo.
echo [STAGE] === !STAGE_NAME! ===
if not "!STAGE_DESC!"=="" echo [INFO]  !STAGE_DESC!

for /f %%T in ('jq ".stages[!STAGE_IDX!].tasks | length" "%PLAN_FILE%"') do set "TOTAL_TASKS=%%T"
set "TASK_IDX=0"

:task_loop
if !TASK_IDX! geq !TOTAL_TASKS! (
    set /a STAGE_IDX+=1
    goto stage_loop
)

for /f "delims=" %%A in ('jq -r ".stages[!STAGE_IDX!].tasks[!TASK_IDX!].name" "%PLAN_FILE%"') do set "TASK_NAME=%%A"
for /f "delims=" %%B in ('jq -r ".stages[!STAGE_IDX!].tasks[!TASK_IDX!].component" "%PLAN_FILE%"') do set "TASK_COMP=%%B"
for /f "delims=" %%C in ('jq -r ".stages[!STAGE_IDX!].tasks[!TASK_IDX!].action" "%PLAN_FILE%"') do set "TASK_ACTION=%%C"
for /f "delims=" %%E in ('jq -r ".stages[!STAGE_IDX!].tasks[!TASK_IDX!].stamp" "%PLAN_FILE%"') do set "TASK_STAMP=%%E"
set "STAMP_FILE=%STAMPS_DIR%\!TASK_STAMP!"

if exist "!STAMP_FILE!" (
    echo [SKIP]  Task "!TASK_NAME!" ^(!TASK_ACTION!^) already satisfied by !TASK_STAMP!
) else (
    echo [RUN]   Task "!TASK_NAME!" ^(!TASK_ACTION!^) [!TASK_COMP!]
    if "!DRY_RUN!"=="1" (
        echo [DRYRUN] Would execute !TASK_ACTION! on !TASK_COMP! and touch !STAMP_FILE!
    ) else (
        set "EXEC_CMD=%REPO_ROOT%!TASK_COMP!\setup.cmd"
        if exist "!EXEC_CMD!" (
            call "!EXEC_CMD!" !TASK_ACTION!
        ) else (
            echo [INFO]  No leaf script !EXEC_CMD!; registering step completion
        )
        echo completed > "!STAMP_FILE!.tmp"
        move /y "!STAMP_FILE!.tmp" "!STAMP_FILE!" >nul
        echo [OK]    Completed "!TASK_NAME!" -^> !TASK_STAMP!
    )
)

set /a TASK_IDX+=1
goto task_loop

:all_done
echo.
echo [SUCCESS] All execution plan stages processed successfully.
endlocal
