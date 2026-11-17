@echo off
:: # parse_connection_uri.cmd
:: ## Overview
:: Universal connection URI parser for database connection strings on Windows.
:: Supports mysql://, postgres://, mongodb://, redis://, sqlite:// using native `jq`
:: (zero PowerShell required) with PowerShell fallback.
::
:: ## Usage
:: parse_connection_uri.cmd <URI> [--eval | --json | --export | --env]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

set "URI=%~1"
set "MODE=%~2"
if "%MODE%"=="" set "MODE=--eval"

if "%URI%"=="" (
    echo Error: URI required 1>&2
    exit /b 1
)

where jq >nul 2>&1
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
    )
)

where jq >nul 2>&1
if not errorlevel 1 (
    call :parse_with_jq
    exit /b !ERRORLEVEL!
)

where powershell >nul 2>&1
if not errorlevel 1 (
    call :parse_with_powershell
    exit /b !ERRORLEVEL!
)

echo Error: Neither jq nor PowerShell available to parse connection URI 1>&2
exit /b 1

:: ## parse_with_jq
:: Parses connection URI components, percent-encoded credentials, and SSL query parameters via jq.
:parse_with_jq
set "_JQ_PROG=%TEMP%\ls_puri_%RANDOM%_%RANDOM%.jq"
(
    echo def pct_dec: gsub^("%%20";" "^)^|gsub^("%%21";"!"^)^|gsub^("%%40";"@"^)^|gsub^("%%23";"#"^)^|gsub^("%%24";"$"^)^|gsub^("%%25";"%%"^)^|gsub^("%%5[Ee]";"^"^)^|gsub^("%%26";"&"^)^|gsub^("%%2[Aa]";"*"^)^|gsub^("%%3[Dd]";"="^);
    echo ^($uri ^| split^("://"^)^) as $p ^|
    echo ^($p[0] // ""^) as $engine ^|
    echo ^($p[1:] ^| join^("://"^)^) as $rest ^|
    echo ^(if ^($rest ^| contains^("@"^)^) then ^($rest ^| split^("@"^)^) else ["", $rest] end^) as $at ^|
    echo ^($at[0]^) as $creds ^|
    echo ^($at[1:] ^| join^("@"^)^) as $hpp ^|
    echo ^(if $creds == "" then ["",""] elif ^($creds ^| contains^(":"^)^) then [ ^($creds^|split^(":"^)[0]^), ^($creds^|split^(":"^)[1:]^|join^(":"^)^) ] else [$creds, ""] end^) as $up ^|
    echo ^($hpp ^| split^("?"^)^) as $qp ^|
    echo ^($qp[1:] ^| join^("?"^)^) as $query ^|
    echo ^($qp[0] ^| split^("/"^)^) as $sp ^|
    echo ^($sp[0]^) as $hp ^|
    echo ^($sp[1:] ^| join^("/"^)^) as $dbname ^|
    echo ^(if ^($hp ^| contains^(":"^)^) then [ ^($hp^|split^(":"^)[0]^), ^($hp^|split^(":"^)[1]^)] else [$hp, ""] end^) as $host_pair ^|
    echo ^(reduce ^($query ^| split^("&"^)[] ^| select^(length ^> 0^)^) as $item ^({use_ssl:"0",ssl_ca:"",ssl_cert:"",ssl_key:"",ssl_mode:"",timeout:"",charset:""};
    echo   ^($item ^| split^("="^)^) as $kv ^| ^($kv[0]^) as $k ^| ^($kv[1:]^|join^("="^)^) as $v ^|
    echo   if ^($k=="ssl-ca" or $k=="ssl_ca"^) then .ssl_ca=$v ^| .use_ssl="1"
    echo   elif ^($k=="ssl-cert" or $k=="ssl_cert"^) then .ssl_cert=$v ^| .use_ssl="1"
    echo   elif ^($k=="ssl-key" or $k=="ssl_key"^) then .ssl_key=$v ^| .use_ssl="1"
    echo   elif ^($k=="ssl-mode" or $k=="sslmode"^) then .ssl_mode=$v ^| .use_ssl="1"
    echo   elif ^($k=="timeout" or $k=="connect_timeout"^) then .timeout=$v
    echo   elif $k=="charset" then .charset=$v
    echo   elif ^($k=="ssl" and ^($v=="true" or $v=="1"^)^) then .use_ssl="1"
    echo   else . end^)^) as $q ^|
    echo {engine:$engine,host:$host_pair[0],port:$host_pair[1],user:^($up[0]^|pct_dec^),pass:^($up[1]^|pct_dec^),dbname:$dbname,query:$query,use_ssl:^($q.use_ssl^|tonumber^),ssl_ca:$q.ssl_ca,ssl_cert:$q.ssl_cert,ssl_key:$q.ssl_key,ssl_mode:$q.ssl_mode,timeout:$q.timeout,charset:$q.charset} ^|
    echo if $mode == "--json" then
    echo   tojson
    echo elif $mode == "--export" then
    echo   ^(
    echo     "export DB_ENGINE=" + ^(.engine^|@json^),
    echo     "export DB_HOST=" + ^(.host^|@json^),
    echo     "export DB_PORT=" + ^(.port^|@json^),
    echo     "export DB_USER=" + ^(.user^|@json^),
    echo     "export DB_PASS=" + ^(.pass^|@json^),
    echo     "export DB_NAME=" + ^(.dbname^|@json^),
    echo     "export DB_QUERY=" + ^(.query^|@json^),
    echo     "export DB_USE_SSL=" + ^(.use_ssl^|tostring^|@json^),
    echo     "export DB_SSL_CA=" + ^(.ssl_ca^|@json^),
    echo     "export DB_SSL_CERT=" + ^(.ssl_cert^|@json^),
    echo     "export DB_SSL_KEY=" + ^(.ssl_key^|@json^),
    echo     "export DB_SSL_MODE=" + ^(.ssl_mode^|@json^),
    echo     "export DB_TIMEOUT=" + ^(.timeout^|@json^),
    echo     "export DB_CHARSET=" + ^(.charset^|@json^)
    echo   ^)
    echo else
    echo   ^(
    echo     "set " + ^(("DB_ENGINE=" + .engine^)^|@json^),
    echo     "set " + ^(("DB_HOST=" + .host^)^|@json^),
    echo     "set " + ^(("DB_PORT=" + .port^)^|@json^),
    echo     "set " + ^(("DB_USER=" + .user^)^|@json^),
    echo     "set " + ^(("DB_PASS=" + .pass^)^|@json^),
    echo     "set " + ^(("DB_NAME=" + .dbname^)^|@json^),
    echo     "set " + ^(("DB_QUERY=" + .query^)^|@json^),
    echo     "set " + ^(("DB_USE_SSL=" + ^(.use_ssl^|tostring^)^)^|@json^),
    echo     "set " + ^(("DB_SSL_CA=" + .ssl_ca^)^|@json^),
    echo     "set " + ^(("DB_SSL_CERT=" + .ssl_cert^)^|@json^),
    echo     "set " + ^(("DB_SSL_KEY=" + .ssl_key^)^|@json^),
    echo     "set " + ^(("DB_SSL_MODE=" + .ssl_mode^)^|@json^),
    echo     "set " + ^(("DB_TIMEOUT=" + .timeout^)^|@json^),
    echo     "set " + ^(("DB_CHARSET=" + .charset^)^|@json^)
    echo   ^)
    echo end
) > "!_JQ_PROG!"
jq -rn --arg uri "!URI!" --arg mode "!MODE!" -f "!_JQ_PROG!"
set "_JQ_RC=!ERRORLEVEL!"
del /f /q "!_JQ_PROG!" >nul 2>&1
exit /b !_JQ_RC!

:: ## parse_with_powershell
:: Fallback connection URI parser using System.Uri when jq is not installed.
:parse_with_powershell
powershell -NoProfile -Command "$u = [System.Uri]$env:URI; $engine = $u.Scheme; $dbhost = $u.Host; $port = if ($u.Port -gt 0) { $u.Port } else { '' }; $user=''; $pass=''; if ($u.UserInfo) { $parts = $u.UserInfo -split ':',2; $user = [uri]::UnescapeDataString($parts[0]); if ($parts.Length -gt 1) { $pass = [uri]::UnescapeDataString($parts[1]) } }; $db = $u.AbsolutePath.TrimStart('/'); $query = $u.Query.TrimStart('?'); if ($env:MODE -eq '--json') { Write-Output ('{"engine":"'+$engine+'","host":"'+$dbhost+'","port":"'+$port+'","user":"'+$user+'","pass":"'+$pass+'","dbname":"'+$db+'","query":"'+$query+'","use_ssl":0,"ssl_ca":"","ssl_cert":"","ssl_key":"","ssl_mode":"","timeout":"","charset":""}') } else { Write-Output ('set "DB_ENGINE='+$engine+'"'); Write-Output ('set "DB_HOST='+$dbhost+'"'); Write-Output ('set "DB_PORT='+$port+'"'); Write-Output ('set "DB_USER='+$user+'"'); Write-Output ('set "DB_PASS='+$pass+'"'); Write-Output ('set "DB_NAME='+$db+'"'); Write-Output ('set "DB_QUERY='+$query+'"') }"
exit /b !ERRORLEVEL!
