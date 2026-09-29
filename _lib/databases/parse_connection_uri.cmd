@echo off
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

:: # parse_connection_uri.cmd
::
:: ## Overview
:: Universal database connection URI parser supporting MySQL, MariaDB, PostgreSQL,
:: MongoDB, Redis, and SQLite on Windows.
::
:: ## Usage
::   call parse_connection_uri.cmd <URI> [--eval^|--json^|--export]

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root

set "RAW_URI=%~1"
set "MODE=%~2"
if "%MODE%"=="" set "MODE=--eval"

if "%RAW_URI%"=="" (
    echo [ERROR] No URI provided to parse_connection_uri.cmd >&2
    exit /b 1
)

:: ## execute_powershell_parser
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$raw = '%RAW_URI%';" ^
    "$mode = '%MODE%';" ^
    "if ($raw -match '^(?<scheme>[a-zA-Z0-9]+)://(?<rest>.*)$') {" ^
    "  $scheme = $matches['scheme'].ToLower();" ^
    "  $rest = $matches['rest'];" ^
    "} else {" ^
    "  $scheme = 'mysql';" ^
    "  $rest = $raw;" ^
    "};" ^
    "if ($scheme -eq 'postgresql') { $scheme = 'postgres'; };" ^
    "if ($scheme -eq 'sqlite') {" ^
    "  $p = $rest.Split('?')[0];" ^
    "  if ($mode -eq '--json') { ConvertTo-Json @{engine='sqlite'; path=$p} } " ^
    "  else { Write-Output ('DB_ENGINE=sqlite`nDB_PATH=' + $p) };" ^
    "  exit 0;" ^
    "};" ^
    "$defPort = 3306;" ^
    "if ($scheme -eq 'postgres') { $defPort = 5432; } elseif ($scheme -eq 'mongodb') { $defPort = 27017; } elseif ($scheme -eq 'redis') { $defPort = 6379; };" ^
    "$query = '';" ^
    "if ($rest.Contains('?')) {" ^
    "  $parts = $rest.Split('?', 2);" ^
    "  $rest = $parts[0];" ^
    "  $query = $parts[1];" ^
    "};" ^
    "$name = '';" ^
    "if ($rest.Contains('/')) {" ^
    "  $parts = $rest.Split('/', 2);" ^
    "  $rest = $parts[0];" ^
    "  $name = $parts[1];" ^
    "};" ^
    "$user = ''; $pass = '';" ^
    "if ($rest.Contains('@')) {" ^
    "  $parts = $rest.Split('@', 2);" ^
    "  $auth = $parts[0];" ^
    "  $rest = $parts[1];" ^
    "  if ($auth.Contains(':')) {" ^
    "    $ap = $auth.Split(':', 2);" ^
    "    $user = [System.Uri]::UnescapeDataString($ap[0]);" ^
    "    $pass = [System.Uri]::UnescapeDataString($ap[1]);" ^
    "  } else {" ^
    "    $user = [System.Uri]::UnescapeDataString($auth);" ^
    "  }" ^
    "};" ^
    "$host_val = '127.0.0.1'; $port = $defPort;" ^
    "if ($rest.Contains(':')) {" ^
    "  $hp = $rest.Split(':', 2);" ^
    "  $host_val = $hp[0];" ^
    "  $port = [int]$hp[1];" ^
    "} elseif ($rest -ne '') {" ^
    "  $host_val = $rest;" ^
    "};" ^
    "$use_ssl = $false; $ssl_ca = ''; $ssl_cert = ''; $ssl_key = ''; $ssl_mode = ''; $timeout = ''; $charset = '';" ^
    "if ($query -ne '') {" ^
    "  $use_ssl = $true;" ^
    "  foreach ($pair in $query.Split('&')) {" ^
    "    $kv = $pair.Split('=', 2);" ^
    "    $k = $kv[0].ToLower(); $v = ''; if ($kv.Length -gt 1) { $v = [System.Uri]::UnescapeDataString($kv[1]); };" ^
    "    if ($k -in @('ssl-ca','ssl_ca')) { $ssl_ca = $v; }" ^
    "    elseif ($k -in @('ssl-cert','ssl_cert')) { $ssl_cert = $v; }" ^
    "    elseif ($k -in @('ssl-key','ssl_key')) { $ssl_key = $v; }" ^
    "    elseif ($k -in @('ssl-mode','ssl_mode')) { $ssl_mode = $v; }" ^
    "    elseif ($k -in @('timeout')) { $timeout = $v; }" ^
    "    elseif ($k -in @('charset')) { $charset = $v; }" ^
    "  }" ^
    "};" ^
    "if ($mode -eq '--json') {" ^
    "  ConvertTo-Json @{engine=$scheme; host=$host_val; port=$port; name=$name; user=$user; password=$pass; use_ssl=$use_ssl; ssl_ca=$ssl_ca; ssl_cert=$ssl_cert; ssl_key=$ssl_key; ssl_mode=$ssl_mode; timeout=$timeout; charset=$charset} -Compress:$false;" ^
    "} else {" ^
    "  Write-Output ('DB_ENGINE=' + $scheme);" ^
    "  Write-Output ('DB_HOST=' + $host_val);" ^
    "  Write-Output ('DB_PORT=' + $port);" ^
    "  Write-Output ('DB_NAME=' + $name);" ^
    "  Write-Output ('DB_USER=' + $user);" ^
    "  Write-Output ('DB_PASSWORD=' + $pass);" ^
    "  Write-Output ('DB_USE_SSL=' + $(if ($use_ssl) { '1' } else { '0' }));" ^
    "  Write-Output ('DB_SSL_CA=' + $ssl_ca);" ^
    "  Write-Output ('DB_SSL_CERT=' + $ssl_cert);" ^
    "  Write-Output ('DB_SSL_KEY=' + $ssl_key);" ^
    "  Write-Output ('DB_SSL_MODE=' + $ssl_mode);" ^
    "  Write-Output ('DB_TIMEOUT=' + $timeout);" ^
    "  Write-Output ('DB_CHARSET=' + $charset);" ^
    "}"

exit /b %ERRORLEVEL%
