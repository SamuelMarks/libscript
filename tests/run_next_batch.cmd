@echo off
:: # run_next_batch.cmd
:: ## Overview
:: Reads TODO_PLAN.md and returns the next batch of up to 5 uncompleted tasks.
::
:: ## Usage
:: run_next_batch.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

set "THIS_DIR=%~dp0"
:: Remove trailing slash
set "THIS_DIR=%THIS_DIR:~0,-1%"
set "REPO_ROOT=%THIS_DIR%\.."
set "TODO_FILE=%REPO_ROOT%\TODO_PLAN.md"

if not exist "%TODO_FILE%" goto :eof

set "BATCH="
set "COUNT=0"

for /f "usebackq tokens=*" %%A in ("%TODO_FILE%") do (
    set "LINE=%%A"
    if "!LINE:~0,6!"=="- [ ] " (
        set "ITEM=!LINE:~6!"
        echo !ITEM! | findstr /c:"**`_lib/" >nul
        if not errorlevel 1 (
            for /f "tokens=2 delims=/" %%B in ("!ITEM!") do (
                for /f "tokens=1 delims=`*" %%C in ("%%B") do (
                    set "ITEM=%%C"
                )
            )
        )
        set "BATCH=!BATCH! !ITEM!"
        set /a COUNT+=1
        if !COUNT! GEQ 5 goto :done
    )
)

:: ## done
:: Performs the done operation and updates component state.
:done
if not "!BATCH!"=="" (
    REM Trim leading space
    set "BATCH=!BATCH:~1!"
    echo !BATCH!
)
endlocal
goto :eof
