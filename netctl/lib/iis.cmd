@echo off
setlocal EnableDelayedExpansion
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<configuration^>
echo   ^<system.webServer^>
echo     ^<rewrite^>
echo       ^<rules^>

set RULE_ID=1
for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="proxy" (
        echo         ^<rule name="ReverseProxy!RULE_ID!" stopProcessing="true"^>
        echo           ^<match url="^%%a(.*)" /^>
        echo           ^<action type="Rewrite" url="%%c/{R:1}" /^>
        echo         ^</rule^>
        set /a RULE_ID+=1
    ) else if "%%b"=="rewrite" (
        echo         ^<rule name="Rewrite!RULE_ID!" stopProcessing="true"^>
        echo           ^<match url="^%%a(.*)" /^>
        echo           ^<action type="Rewrite" url="%%d" /^>
        echo         ^</rule^>
        set /a RULE_ID+=1
    )
)

echo       ^</rules^>
echo     ^</rewrite^>

:: Note: IIS `appcmd` is usually required for setting Listen ports and Static paths via Virtual Directories.
:: The web.config handles the rewriting and proxying.
:: We will emit comments on how to complete the IIS setup.

echo     ^<!-- To complete IIS Setup for Static paths and Listeners: --^>
for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo     ^<!-- appcmd set site /site.name:"Default Web Site" /+bindings.[protocol='http',bindingInformation='*:%%i:'] --^>
)

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="static" (
        echo     ^<!-- appcmd add vdir /app.name:"Default Web Site/" /path:"%%a" /physicalPath:"%%c" --^>
    )
)

echo   ^</system.webServer^>
echo ^</configuration^>
exit /b 0
