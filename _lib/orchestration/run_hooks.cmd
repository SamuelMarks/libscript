@echo off
setlocal enabledelayedexpansion

set json_file=%~1
set hook_type=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".hooks.%hook_type%[]?" "%json_file%" 2^>nul') do (
    set "hook=%%i"
    for /f "delims=" %%n in ('echo !hook! ^| jq -r ".name // \"unnamed_hook\""') do set "name=%%n"
    for /f "delims=" %%c in ('echo !hook! ^| jq -r ".command // empty"') do set "cmd=%%c"
    for /f "delims=" %%d in ('echo !hook! ^| jq -r ".condition // empty"') do set "cond=%%d"
    
    set skip=0
    if not "!cond!"=="" (
        echo !cond! | findstr /b /c:"unless_exists " >nul
        if not errorlevel 1 (
            set "file=!cond:unless_exists =!"
            if exist "!file!" (
                echo Skipping hook '!name!': !file! exists
                set skip=1
            )
        )
    )
    
    if "!skip!"=="0" if not "!cmd!"=="" (
        echo Executing hook '!name!': !cmd!
        call !cmd!
    )
)
exit /b 0
