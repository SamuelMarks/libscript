@echo off
setlocal enabledelayedexpansion

set action=%~1
set json_file=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".services[]?" "%json_file%" 2^>nul') do (
    set "svc=%%i"
    for /f "delims=" %%n in ('echo !svc! ^| jq -r ".name // empty"') do set "name=%%n"
    for /f "delims=" %%c in ('echo !svc! ^| jq -r ".command // empty"') do set "cmd=%%c"
    
    if not "!name!"=="" if not "!cmd!"=="" (
        if /i "!action!"=="start" (
            echo Configuring and starting service '!name!'...
            if not exist "\tmp\data\!name!" mkdir "\tmp\data\!name!" 2>nul
            
            rem Set environments inline
            for /f "delims=" %%e in ('echo !svc! ^| jq -r ".env | to_entries[]? | \"set \\\"\(.key)=\(.value)\\\"\"" 2^>nul') do (
                %%e
            )
            
            rem Enumerate env files (basic naive support)
            for /f "delims=" %%f in ('echo !svc! ^| jq -r ".env_files[]?" 2^>nul') do (
                if exist "%%f" (
                    for /f "tokens=* delims=" %%l in (%%f) do set "%%l"
                )
            )

            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="up" (
            echo Configuring and starting service '!name!'...
            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="stop" (
            echo Stopping service '!name!'...
            rem Complex to kill without PID, could use taskkill with window title
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
        if /i "!action!"=="down" (
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
    )
)
exit /b 0
