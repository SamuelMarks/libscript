@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

set PORTS=
for /f "delims=" %%p in ('jq -r "if (.listen | length) > 0 then .listen | map(\":\" + .) | join(\", \") else \"localhost\" end" "%NETCTL_STATE_FILE%"') do (
    set PORTS=%%p
)
echo %PORTS% {

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    echo.
    if "%%b"=="static" (
        echo     handle %%a* {
        echo         root * %%c
        echo         file_server
        echo     }
    ) else if "%%b"=="proxy" (
        echo     reverse_proxy %%a* %%c
    ) else if "%%b"=="rewrite" (
        echo     rewrite %%a* %%d
    )
)

echo }
exit /b 0
