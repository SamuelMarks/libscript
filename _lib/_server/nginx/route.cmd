@echo off
set "DOMAIN=%~1"
set "LOCATION=%~2"
set "DESTINATION=%~3"
if "%DOMAIN%"=="" goto usage
if "%LOCATION%"=="" goto usage
if "%DESTINATION%"=="" goto usage
if "!PREFIX!"=="" (
    set "NGINX_CONF_DIR=!LIBSCRIPT_ROOT_DIR!\installed\nginx\conf"
) else (
    set "NGINX_CONF_DIR=!PREFIX!\conf"
)
if not exist "%NGINX_CONF_DIR%\sites-available" mkdir "%NGINX_CONF_DIR%\sites-available"
if not exist "%NGINX_CONF_DIR%\sites-enabled" mkdir "%NGINX_CONF_DIR%\sites-enabled"
set "CONF_FILE=%NGINX_CONF_DIR%\sites-available\%DOMAIN%.conf"
if not exist "%CONF_FILE%" (
    echo server {> "%CONF_FILE%"
    echo     listen 80;>> "%CONF_FILE%"
    echo     server_name %DOMAIN%;>> "%CONF_FILE%"
    echo }>> "%CONF_FILE%"
)
findstr /v /c:"}" "%CONF_FILE%" > "%CONF_FILE%.tmp"
echo     location %LOCATION% {>> "%CONF_FILE%.tmp"
echo         proxy_pass %DESTINATION%;>> "%CONF_FILE%.tmp"
echo         proxy_set_header Host $host;>> "%CONF_FILE%.tmp"
echo         proxy_set_header X-Real-IP $remote_addr;>> "%CONF_FILE%.tmp"
echo     }>> "%CONF_FILE%.tmp"
echo }>> "%CONF_FILE%.tmp"
move /y "%CONF_FILE%.tmp" "%CONF_FILE%" >nul
copy /y "%CONF_FILE%" "%NGINX_CONF_DIR%\sites-enabled\%DOMAIN%.conf" >nul
echo Route added: %DOMAIN%%LOCATION% -^> %DESTINATION%
exit /b 0
:usage
echo Usage: libscript.cmd route nginx ^<version^> ^<domain^> ^<location^> ^<destination^> 1^>^&2
exit /b 1
