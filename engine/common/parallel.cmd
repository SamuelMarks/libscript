@echo off
:: # parallel.cmd
:: ## Overview
:: Tier 0 (`T0`) zero-PowerShell Windows Batch parallel worker pool and static sharding engine (`parallel.cmd`),
:: auto-detecting CPU cores via `hw_tune.cmd`, honoring `LIBSCRIPT_JOBS`, and gracefully falling back to
:: sequential `call` execution (`1`) on MS-DOS (`IS_MSDOS=1` / `COMMAND.COM` / `ls_wincmd`).
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\engine\common\parallel.cmd" :detect_jobs
:: call "%LIBSCRIPT_ROOT_DIR%\engine\common\parallel.cmd" :run_tasks <tasks_file> [max_jobs]
:: call "%LIBSCRIPT_ROOT_DIR%\engine\common\parallel.cmd" :run_shards <list_file> <worker_cmd> [max_jobs]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if not defined STACK goto :par_stack_ok
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
goto :par_stack_ok
:: ## par_stack_ok
:: Continues once STACK recursion check passes.
:par_stack_ok
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if defined LIBSCRIPT_ROOT_DIR goto :root_found
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

set "_PAR_SUB=%~1"
if "!_PAR_SUB!"=="" goto :detect_jobs
if not "!_PAR_SUB:~0,1!"==":" goto :detect_jobs
shift
goto !_PAR_SUB!

:: ## resolve_jobs_internal
:: Computes worker count into _PAR_JOBS and background support flag into _PAR_OK within the current scope.
:resolve_jobs_internal
set "_PAR_JOBS=1"
set "_PAR_OK=0"

if "%IS_MSDOS%"=="1" exit /b 0
if "%LIBSCRIPT_DOS_83%"=="1" exit /b 0
if /I "%OS%"=="MS-DOS" exit /b 0
if /I not "%OS%"=="Windows_NT" exit /b 0

set "_PAR_EXPLICIT=0"
if not "%LIBSCRIPT_JOBS%"=="" (
    set /a "_PAR_TRY=%LIBSCRIPT_JOBS%" 2>nul
    REM wincheck disable=CMD2003
    if !_PAR_TRY! geq 1 (
        set "_PAR_JOBS=!_PAR_TRY!"
        set "_PAR_EXPLICIT=1"
    )
)

if "!_PAR_EXPLICIT!"=="0" (
    if "%LIBSCRIPT_HW_CORES%"=="" (
        if exist "!LIBSCRIPT_ROOT_DIR!\engine\common\hw_tune.cmd" (
            set "_PAR_SAVED_ST=!STACK!"
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\engine\common\hw_tune.cmd" :libscript_detect_hardware
            set "STACK=!_PAR_SAVED_ST!"
        )
    )
    set "_PAR_CORES=!LIBSCRIPT_HW_CORES!"
    if "!_PAR_CORES!"=="" set "_PAR_CORES=%NUMBER_OF_PROCESSORS%"
    if "!_PAR_CORES!"=="" set "_PAR_CORES=4"
    set /a "_PAR_JOBS=!_PAR_CORES!" 2>nul
    REM wincheck disable=CMD2003
    if !_PAR_JOBS! lss 1 set "_PAR_JOBS=1"
    REM wincheck disable=CMD2003
    if !_PAR_JOBS! gtr 16 set "_PAR_JOBS=16"
)

REM wincheck disable=CMD2003
if !_PAR_JOBS! leq 1 (
    set "_PAR_JOBS=1"
    set "_PAR_OK=0"
    exit /b 0
)

set "_PAR_OK=1"
exit /b 0

:: ## detect_jobs
:: Exports LIBSCRIPT_RESOLVED_JOBS and LIBSCRIPT_PARALLEL_SUPPORTED to the caller environment.
:detect_jobs
call :resolve_jobs_internal
endlocal&set "LIBSCRIPT_RESOLVED_JOBS=%_PAR_JOBS%"&set "LIBSCRIPT_PARALLEL_SUPPORTED=%_PAR_OK%"
exit /b 0

:: ## run_tasks
:: Executes Batch commands listed one-per-line in %~1 concurrently up to %~2 workers via start /b, or sequentially on MS-DOS.
:run_tasks
set "_RT_FILE=%~1"
set "_RT_CAP=%~2"
if "!_RT_FILE!"=="" exit /b 0
if not exist "!_RT_FILE!" exit /b 0

call :resolve_jobs_internal
if not "!_RT_CAP!"=="" (
    set /a "_RT_CAP_N=!_RT_CAP!" 2>nul
    REM wincheck disable=CMD2003
    if !_RT_CAP_N! geq 1 (
        REM wincheck disable=CMD2003
        if !_RT_CAP_N! lss !_PAR_JOBS! set "_PAR_JOBS=!_RT_CAP_N!"
    )
)

REM wincheck disable=CMD2003
if !_PAR_JOBS! leq 1 set "_PAR_OK=0"
if "!_PAR_OK!"=="0" goto :run_tasks_serial

set "_RT_BASE=%TEMP%"
if "!_RT_BASE!"=="" set "_RT_BASE=!LIBSCRIPT_ROOT_DIR!\tests_tmp"
set "_RT_JOB_DIR=!_RT_BASE!\lsp_j_!RANDOM!_!RANDOM!"
if not exist "!_RT_JOB_DIR!" mkdir "!_RT_JOB_DIR!"

set /a "_RT_TOTAL=0"
set /a "_RT_RUNNING=0"
set "_RT_FAILED=0"

for /f "usebackq delims=" %%L in ("!_RT_FILE!") do (
    set "_RT_LINE=%%L"
    if not "!_RT_LINE!"=="" (
        call :throttle_pool
        set /a "_RT_TOTAL+=1"
        set "_RT_ID=!_RT_TOTAL!"
        call :spawn_one_task "!_RT_ID!"
    )
)

call :wait_all_tasks
if exist "!_RT_JOB_DIR!" rmdir /s /q "!_RT_JOB_DIR!" >nul 2>&1
if "!_RT_FAILED!"=="1" exit /b 1
exit /b 0

:: ## run_tasks_serial
:: Sequential fallback runner for MS-DOS, single-core hosts, or LIBSCRIPT_JOBS=1.
:run_tasks_serial
set "_RTS_FAILED=0"
for /f "usebackq delims=" %%L in ("!_RT_FILE!") do (
    set "_RTS_CMD=%%L"
    if not "!_RTS_CMD!"=="" (
        set "_RTS_SAVED_ST=!STACK!"
        set "STACK="
        call !_RTS_CMD!
        if errorlevel 1 set "_RTS_FAILED=1"
        set "STACK=!_RTS_SAVED_ST!"
    )
)
if "!_RTS_FAILED!"=="1" exit /b 1
exit /b 0

:: ## spawn_one_task
:: Writes an isolated job wrapper script and launches it via start /b with live console output.
:spawn_one_task
set "_SOT_ID=%~1"
set "_SOT_CMD=!_RT_JOB_DIR!\J!_SOT_ID!.CMD"
set "_SOT_TMP=!_RT_JOB_DIR!\J!_SOT_ID!.TMP"
set "_SOT_RC=!_RT_JOB_DIR!\J!_SOT_ID!.RC"
>"!_SOT_CMD!" echo @echo off
>>"!_SOT_CMD!" echo set "STACK="
>>"!_SOT_CMD!" echo.!_RT_LINE!
>>"!_SOT_CMD!" echo set "_JRC=%%ERRORLEVEL%%"
>>"!_SOT_CMD!" echo echo %%_JRC%% ^> "!_SOT_TMP!"
>>"!_SOT_CMD!" echo move /y "!_SOT_TMP!" "!_SOT_RC!" ^>nul 2^>^&1
>>"!_SOT_CMD!" echo exit /b %%_JRC%%
set /a "_RT_RUNNING+=1"
start "" /b "%ComSpec%" /c call "!_SOT_CMD!"
exit /b 0

:: ## reap_completed
:: Harvests finished worker sentinel files and updates _RT_RUNNING and _RT_FAILED.
:reap_completed
REM wincheck disable=CMD2003
if !_RT_TOTAL! leq 0 exit /b 0
for /L %%I in (1,1,!_RT_TOTAL!) do (
    if not defined _RT_DONE_%%I (
        if exist "!_RT_JOB_DIR!\J%%I.RC" (
            set "_RT_DONE_%%I=1"
            set /a "_RT_RUNNING-=1"
            set "_RT_CODE=0"
            for /f "usebackq tokens=1" %%C in ("!_RT_JOB_DIR!\J%%I.RC") do set "_RT_CODE=%%C"
            if not "!_RT_CODE!"=="0" set "_RT_FAILED=1"
        )
    )
)
exit /b 0

:: ## sleep_brief
:: Pauses ~50ms between poll iterations without PowerShell to avoid CPU spin.
:sleep_brief
where pathping >nul 2>&1
if not errorlevel 1 (
    pathping -n -q 1 -p 50 127.0.0.1 >nul 2>&1
    exit /b 0
)
ping -n 1 -w 50 127.0.0.1 >nul 2>&1
exit /b 0

:: ## throttle_pool
:: Blocks until active background workers drop below _PAR_JOBS.
:throttle_pool
call :reap_completed
REM wincheck disable=CMD2003
if !_RT_RUNNING! lss !_PAR_JOBS! exit /b 0
call :sleep_brief
goto :throttle_pool

:: ## wait_all_tasks
:: Waits until every spawned background job writes its atomic .RC sentinel file.
:wait_all_tasks
call :reap_completed
REM wincheck disable=CMD2003
if !_RT_RUNNING! leq 0 exit /b 0
call :sleep_brief
goto :wait_all_tasks

:: ## run_shards
:: Splits non-empty lines of %~1 into static shards and invokes worker script %~2 concurrently across workers.
:run_shards
set "_RS_LIST=%~1"
set "_RS_WORKER=%~2"
set "_RS_CAP=%~3"
if "!_RS_LIST!"=="" exit /b 0
if not exist "!_RS_LIST!" exit /b 0

call :resolve_jobs_internal
if not "!_RS_CAP!"=="" (
    set /a "_RS_CAP_N=!_RS_CAP!" 2>nul
    REM wincheck disable=CMD2003
    if !_RS_CAP_N! geq 1 (
        REM wincheck disable=CMD2003
        if !_RS_CAP_N! lss !_PAR_JOBS! set "_PAR_JOBS=!_RS_CAP_N!"
    )
)

REM wincheck disable=CMD2003
if !_PAR_JOBS! leq 1 (
    set "_RS_SAVED_ST=!STACK!"
    set "STACK="
    call "!_RS_WORKER!" "!_RS_LIST!"
    set "_RS_RC=!ERRORLEVEL!"
    set "STACK=!_RS_SAVED_ST!"
    exit /b !_RS_RC!
)

if "!_PAR_OK!"=="0" (
    set "_RS_SAVED_ST=!STACK!"
    set "STACK="
    call "!_RS_WORKER!" "!_RS_LIST!"
    set "_RS_RC=!ERRORLEVEL!"
    set "STACK=!_RS_SAVED_ST!"
    exit /b !_RS_RC!
)

set "_RS_BASE=%TEMP%"
if "!_RS_BASE!"=="" set "_RS_BASE=!LIBSCRIPT_ROOT_DIR!\tests_tmp"
set "_RS_DIR=!_RS_BASE!\lsp_s_!RANDOM!_!RANDOM!"
if not exist "!_RS_DIR!" mkdir "!_RS_DIR!"

set /a "_RS_CNT=0"
set /a "_RS_MOD=0"
for /f "usebackq delims=" %%X in ("!_RS_LIST!") do (
    set "_RS_ITEM=%%X"
    if not "!_RS_ITEM!"=="" (
        set /a "_RS_MOD+=1"
        REM wincheck disable=CMD2003
        if !_RS_MOD! gtr !_PAR_JOBS! set "_RS_MOD=1"
        set /a "_RS_CNT+=1"
        >>"!_RS_DIR!\S!_RS_MOD!.TXT" echo.!_RS_ITEM!
    )
)

REM wincheck disable=CMD2003
if !_RS_CNT! leq 0 (
    rmdir /s /q "!_RS_DIR!" >nul 2>&1
    exit /b 0
)

set "_RS_TASKS=!_RS_DIR!\TASKS.TXT"
type nul > "!_RS_TASKS!"
for /L %%S in (1,1,!_PAR_JOBS!) do (
    if exist "!_RS_DIR!\S%%S.TXT" (
        >>"!_RS_TASKS!" echo call "!_RS_WORKER!" "!_RS_DIR!\S%%S.TXT"
    )
)

call :run_tasks "!_RS_TASKS!" "!_PAR_JOBS!"
set "_RS_FINAL_RC=!ERRORLEVEL!"
if exist "!_RS_DIR!" rmdir /s /q "!_RS_DIR!" >nul 2>&1
exit /b !_RS_FINAL_RC!
