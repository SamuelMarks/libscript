@echo off
:: ## Overview
:: Reads TODO_PLAN.md and returns the next batch of up to 5 uncompleted tasks.
::
:: ## Usage
:: run_next_batch.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
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
        set "BATCH=!BATCH! !ITEM!"
        set /a COUNT+=1
        if !COUNT! GEQ 5 goto :done
    )
)

:done
if not "!BATCH!"=="" (
    :: Trim leading space
    set "BATCH=!BATCH:~1!"
    echo !BATCH!
)
endlocal
goto :eof