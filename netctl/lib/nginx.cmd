@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

echo server {

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo     listen %%i;
)

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    echo.
    echo     location %%a {
    if "%%b"=="static" (
        echo         alias %%c/;
    ) else if "%%b"=="proxy" (
        echo         proxy_pass %%c;
        echo         proxy_set_header Host $host;
        echo         proxy_set_header X-Real-IP $remote_addr;
    ) else if "%%b"=="rewrite" (
        echo         rewrite %%d break;
    )
    echo     }
)

echo }
exit /b 0
