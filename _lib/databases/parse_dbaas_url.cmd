@echo off
:: ## Overview
:: Parses a MySQL/MariaDB DBaaS connection URI string into variables on Windows.
:: Supports authentication, ports, database names, and SSL parameters.
::
:: ## Usage
::   call _lib\databases\parse_dbaas_url.cmd <connection_url> [--eval|--json]
::
:: ## Parameters
::   %1 - Database connection URI
::   %2 - Output mode (--eval, --json; default: --eval)

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "RAW_URL=%~1"
set "MODE=%~2"
if "%MODE%"=="" set "MODE=--eval"

if "%RAW_URL%"=="" (
    echo [ERROR] No connection URL provided to parse_dbaas_url.cmd >&2
    exit /b 1
)

:: Use PowerShell to parse URL and query parameters robustly on Windows
set "PS_CMD=$raw = '%RAW_URL%';"
set "PS_CMD=!PS_CMD! if ($raw -match '^(mysql|mariadb)://(?:(?<user>[^:@]+)(?::(?<pass>[^@]*))?@)?(?<host>[^:/?#]+)(?::(?<port>[0-9]+))?(?:/(?<db>[^?#]*))?(?:\?(?<query>.*))?$') {"
set "PS_CMD=!PS_CMD!   $u = [System.Uri]::UnescapeDataString($Matches['user'] ?? 'root');"
set "PS_CMD=!PS_CMD!   $p = [System.Uri]::UnescapeDataString($Matches['pass'] ?? '');"
set "PS_CMD=!PS_CMD!   $h = $Matches['host'] ?? '127.0.0.1';"
set "PS_CMD=!PS_CMD!   $pt = $Matches['port'] ?? '3306';"
set "PS_CMD=!PS_CMD!   $d = $Matches['db'] ?? 'wordpress';"
set "PS_CMD=!PS_CMD!   $q = $Matches['query'] ?? '';"
set "PS_CMD=!PS_CMD!   $ssl = 0; $ca = ''; $mode = '';"
set "PS_CMD=!PS_CMD!   if ($q) { $ssl = 1; foreach ($part in $q.Split('&')) { $kv = $part.Split('='); if ($kv[0] -match 'ssl-ca|ssl_ca') { $ca = [System.Uri]::UnescapeDataString($kv[1]) } elseif ($kv[0] -match 'ssl-mode|ssl_mode') { $mode = [System.Uri]::UnescapeDataString($kv[1]) } } }"
set "PS_CMD=!PS_CMD!   if ('%MODE%' -eq '--json') { [PSCustomObject]@{host=$h;port=[int]$pt;name=$d;user=$u;password=$p;use_ssl=[bool]$ssl;ssl_ca=$ca;ssl_mode=$mode} | ConvertTo-Json -Compress } else { Write-Output ('DB_HOST=' + $h); Write-Output ('DB_PORT=' + $pt); Write-Output ('DB_NAME=' + $d); Write-Output ('DB_USER=' + $u); Write-Output ('DB_PASSWORD=' + $p); Write-Output ('DB_USE_SSL=' + $ssl); Write-Output ('DB_SSL_CA=' + $ca); Write-Output ('DB_SSL_MODE=' + $mode) }"
set "PS_CMD=!PS_CMD! }"

for /f "usebackq delims=" %%l in (`powershell -NoProfile -Command "!PS_CMD!"`) do (
    echo %%l
)

exit /b 0
