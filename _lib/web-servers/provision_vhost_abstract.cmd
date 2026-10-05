@echo off
REM ==============================================================================
REM ## Overview
REM Provisions a reverse proxy virtual host (Nginx or Apache httpd).
REM Windows Batch equivalent of provision_vhost_abstract.sh
REM Includes idempotent interpolation using block markers and tests.
REM
REM ## Usage
REM provision_vhost_abstract.cmd --app-id <id> --server-name <domain>
REM        [--proxy-engine <nginx|apache2>] [--listen-port <port>]
REM        [--target <url>] [--doc-root <path>] --conf-file <path>
REM ==============================================================================

setlocal EnableExtensions EnableDelayedExpansion

set "THIS_DIR=%~dp0"
set "THIS_FILE=%~f0"

set "APP_ID="
set "SERVER_NAME="
set "PROXY_ENGINE=nginx"
set "LISTEN_PORT=80"
set "TARGET="
set "DOC_ROOT="
set "CONF_FILE="

:parse_args
if "%~1"=="" goto validate_args
if /I "%~1"=="--app-id" (
    set "APP_ID=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--server-name" (
    set "SERVER_NAME=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--proxy-engine" (
    set "PROXY_ENGINE=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--listen-port" (
    set "LISTEN_PORT=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--target" (
    set "TARGET=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--doc-root" (
    set "DOC_ROOT=%~2"
    shift & shift
    goto parse_args
)
if /I "%~1"=="--conf-file" (
    set "CONF_FILE=%~2"
    shift & shift
    goto parse_args
)
echo [ERROR] Unknown argument: %~1 >&2
exit /b 1

:validate_args
if "%APP_ID%"=="" (
    echo [ERROR] --app-id is required >&2
    exit /b 1
)
if "%SERVER_NAME%"=="" (
    echo [ERROR] --server-name is required >&2
    exit /b 1
)
if "%CONF_FILE%"=="" (
    echo [ERROR] --conf-file is required >&2
    exit /b 1
)
goto interpolate_block

:generate_nginx_block
(
    echo # BEGIN libscript-managed: %APP_ID%
    echo server {
    echo     listen %LISTEN_PORT%;
    echo     server_name %SERVER_NAME%;
    if not "%DOC_ROOT%"=="" (
        echo     root %DOC_ROOT%;
        echo     index index.html index.php;
    )
    if not "%TARGET%"=="" (
        echo     location / {
        echo         proxy_pass http://%TARGET%;
        echo         proxy_set_header Host $host;
        echo         proxy_set_header X-Real-IP $remote_addr;
        echo     }
    )
    echo }
    echo # END libscript-managed: %APP_ID%
) > "%NEW_BLOCK_FILE%"
exit /b 0

:generate_apache2_block
(
    echo # BEGIN libscript-managed: %APP_ID%
    echo ^<VirtualHost *:%LISTEN_PORT%^>
    echo     ServerName %SERVER_NAME%
    if not "%DOC_ROOT%"=="" (
        echo     DocumentRoot "%DOC_ROOT%"
    )
    if not "%TARGET%"=="" (
        echo     ProxyPreserveHost On
        echo     ProxyPass / http://%TARGET%/
        echo     ProxyPassReverse / http://%TARGET%/
    )
    echo ^</VirtualHost^>
    echo # END libscript-managed: %APP_ID%
) > "%NEW_BLOCK_FILE%"
exit /b 0

:interpolate_block
set "NEW_BLOCK_FILE=%THIS_DIR%.tmp_block_%APP_ID%"
set "BACKUP_FILE=%CONF_FILE%.bak"
set "AWK_SCRIPT=%THIS_DIR%.tmp_awk_%APP_ID%.awk"

if /I "%PROXY_ENGINE%"=="nginx" (
    call :generate_nginx_block
) else if /I "%PROXY_ENGINE%"=="apache2" (
    call :generate_apache2_block
) else (
    echo [ERROR] Unsupported proxy engine: %PROXY_ENGINE% >&2
    exit /b 1
)

if not exist "%CONF_FILE%" (
    for %%F in ("%CONF_FILE%") do if not exist "%%~dpF" mkdir "%%~dpF"
    copy /y "%NEW_BLOCK_FILE%" "%CONF_FILE%" >nul
) else (
    copy /y "%CONF_FILE%" "%BACKUP_FILE%" >nul
    
    REM Generates the AWK script file to avoid complex Windows escaping
    (
        echo BEGIN {
        echo   begin_marker = "# BEGIN libscript-managed: " "%APP_ID%"
        echo   end_marker = "# END libscript-managed: " "%APP_ID%"
        echo   in_block = 0
        echo   replaced = 0
        echo }
        echo $0 == begin_marker {
        echo   in_block = 1
        echo   while (^(getline line ^< "%NEW_BLOCK_FILE%"^) ^> 0^) {
        echo     print line
        echo   }
        echo   close^("%NEW_BLOCK_FILE%"^)
        echo   replaced = 1
        echo   next
        echo }
        echo $0 == end_marker {
        echo   in_block = 0
        echo   next
        echo }
        echo ^!in_block {
        echo   print $0
        echo }
        echo END {
        echo   if (^\!replaced^) {
        echo     print ""
        echo     while (^(getline line ^< "%NEW_BLOCK_FILE%"^) ^> 0^) {
        echo       print line
        echo     }
        echo     close^("%NEW_BLOCK_FILE%"^)
        echo   }
        echo }
    ) > "%AWK_SCRIPT%"

    REM Use AWK (expected to be present in libscript msi-rs build environments)
    awk -f "%AWK_SCRIPT%" "%BACKUP_FILE%" > "%CONF_FILE%"
    del /f /q "%AWK_SCRIPT%"
)
del /f /q "%NEW_BLOCK_FILE%"
goto test_and_reload

:test_and_reload
set "TEST_CMD="
set "RELOAD_CMD="

if /I "%PROXY_ENGINE%"=="nginx" (
    set "TEST_CMD=nginx.exe -t"
    set "RELOAD_CMD=nginx.exe -s reload"
) else if /I "%PROXY_ENGINE%"=="apache2" (
    set "TEST_CMD=httpd.exe -t"
    REM For Apache on Windows, we restart the service via net
    REM Assuming service name is Apache2.4, this might need parameterization in future
    set "RELOAD_CMD=net stop Apache2.4 && net start Apache2.4"
)

echo [INFO] Testing %PROXY_ENGINE% configuration...
%TEST_CMD%
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Syntax OK. Reloading...
    %RELOAD_CMD%
    if exist "%BACKUP_FILE%" del /f /q "%BACKUP_FILE%"
    echo [PASS] Interpolation successful.
) else (
    echo [ERROR] Syntax test failed. Rolling back changes. >&2
    if exist "%BACKUP_FILE%" (
        move /y "%BACKUP_FILE%" "%CONF_FILE%" >nul
    ) else (
        del /f /q "%CONF_FILE%"
    )
    exit /b 1
)

endlocal
exit /b 0
