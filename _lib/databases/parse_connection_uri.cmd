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

:: ## Overview
:: Parses a database connection URI into shell variables or JSON.
::
:: ## Usage
::   call parse_connection_uri.cmd <URI> [--eval | --json | --export]

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "URI=%~1"
set "MODE=%~2"
if "%MODE%"=="" set "MODE=--eval"

if "%URI%"=="" (
    echo Error: URI required >&2
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u = [System.Uri]'%URI%'; $p = $u.UserInfo.Split(':'); $user = if ($p.Length -gt 0) { [Uri]::UnescapeDataString($p[0]) } else { '' }; $pass = if ($p.Length -gt 1) { [Uri]::UnescapeDataString($p[1]) } else { '' }; $db = $u.AbsolutePath.TrimStart('/'); $query = $u.Query.TrimStart('?'); $engine = $u.Scheme; $host = $u.Host; $port = $u.Port; $use_ssl = '0'; $ssl_ca = ''; $ssl_cert = ''; $ssl_key = ''; $ssl_mode = ''; $timeout = ''; $charset = ''; if ($query) { foreach ($pair in $query.Split('&')) { $kv = $pair.Split('=', 2); if ($kv.Length -ne 2) { continue }; $k = $kv[0].ToLower(); $v = [Uri]::UnescapeDataString($kv[1]); switch ($k) { { $_ -in 'ssl-ca', 'ssl_ca' } { $ssl_ca = $v; $use_ssl = '1' }; { $_ -in 'ssl-cert', 'ssl_cert' } { $ssl_cert = $v; $use_ssl = '1' }; { $_ -in 'ssl-key', 'ssl_key' } { $ssl_key = $v; $use_ssl = '1' }; { $_ -in 'ssl-mode', 'sslmode' } { $ssl_mode = $v; $use_ssl = '1' }; { $_ -in 'timeout', 'connect_timeout' } { $timeout = $v }; 'charset' { $charset = $v }; 'ssl' { if ($v -eq 'true' -or $v -eq '1') { $use_ssl = '1' } } } } }; if ('%MODE%' -eq '--eval' -or '%MODE%' -eq '--export') { Write-Host ""set `""DB_ENGINE=$engine`""`nset `""DB_HOST=$host`""`nset `""DB_PORT=$port`""`nset `""DB_USER=$user`""`nset `""DB_PASS=$pass`""`nset `""DB_NAME=$db`""`nset `""DB_QUERY=$query`""`nset `""DB_USE_SSL=$use_ssl`""`nset `""DB_SSL_CA=$ssl_ca`""`nset `""DB_SSL_CERT=$ssl_cert`""`nset `""DB_SSL_KEY=$ssl_key`""`nset `""DB_SSL_MODE=$ssl_mode`""`nset `""DB_TIMEOUT=$timeout`""`nset `""DB_CHARSET=$charset`"""" } elseif ('%MODE%' -eq '--json') { $obj = @{ engine=$engine; host=$host; port=$port; user=$user; pass=$pass; dbname=$db; query=$query; use_ssl=[int]$use_ssl; ssl_ca=$ssl_ca; ssl_cert=$ssl_cert; ssl_key=$ssl_key; ssl_mode=$ssl_mode; timeout=$timeout; charset=$charset }; $obj | ConvertTo-Json -Compress }"

exit /b %ERRORLEVEL%