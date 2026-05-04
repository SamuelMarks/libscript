@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo Listen %%i
)
echo.

set FIRST_PORT=
for /f "delims=" %%i in ('jq -r ".listen[0] // \"80\"" "%NETCTL_STATE_FILE%"') do (
    set FIRST_PORT=%%i
)

echo ^<VirtualHost *:%FIRST_PORT%^>

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="static" (
        echo     Alias "%%a" "%%c"
        echo     ^<Directory "%%c"^>
        echo         Require all granted
        echo     ^</Directory^>
    ) else if "%%b"=="proxy" (
        echo     ProxyPass "%%a" "%%c"
        echo     ProxyPassReverse "%%a" "%%c"
    ) else if "%%b"=="rewrite" (
        echo     RewriteEngine On
        echo     RewriteRule "^%%a(.*)$" "%%d" [L]
    )
)

echo ^</VirtualHost^>
exit /b 0
