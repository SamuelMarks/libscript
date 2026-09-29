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

:: # discover_databases.cmd
::
:: ## Overview
:: Universal multi-platform database discovery engine on Windows.
:: Inspects Windows Services and TCP listening sockets across MySQL, MariaDB,
:: PostgreSQL, MongoDB, and Redis.
::
:: ## Usage
::   call discover_databases.cmd [--json^|--eval^|--check] [--engine <type>]

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

set "MODE=--check"
set "FILTER_ENGINE="

:parse_args
if "%~1"=="" goto done_args
if /i "%~1"=="--json" (
    set "MODE=--json"
    shift
    goto parse_args
)
if /i "%~1"=="--eval" (
    set "MODE=--eval"
    shift
    goto parse_args
)
if /i "%~1"=="--check" (
    set "MODE=--check"
    shift
    goto parse_args
)
if /i "%~1"=="--engine" (
    set "FILTER_ENGINE=%~2"
    shift
    shift
    goto parse_args
)
shift
goto parse_args

:done_args

:: ## probe_service
:: Checks if a Windows service is actively running and outputs details via PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$mode = '%MODE%';" ^
    "$filter = '%FILTER_ENGINE%';" ^
    "$results = @();" ^
    "$services = @(" ^
    "  @{engine='mysql'; port=3306; names=@('MySQL','MariaDB','MySQL57','MySQL80','OpenEdXMySQL')}," ^
    "  @{engine='postgres'; port=5432; names=@('postgresql','postgresql-x64-14','postgresql-x64-15','postgresql-x64-16')}," ^
    "  @{engine='mongodb'; port=27017; names=@('MongoDB')}," ^
    "  @{engine='redis'; port=6379; names=@('Redis')}" ^
    ");" ^
    "foreach ($s in $services) {" ^
    "  if ($filter -ne '' -and $filter -ne $s.engine) { continue; }" ^
    "  $found = $false;" ^
    "  foreach ($name in $s.names) {" ^
    "    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue;" ^
    "    if ($svc -and $svc.Status -eq 'Running') {" ^
    "      $results += [PSCustomObject]@{engine=$s.engine; version='auto'; host='127.0.0.1'; port=$s.port; service_name=$name; is_active=$true; source='windows_service'; existing_schemas=@()};" ^
    "      $found = $true; break;" ^
    "    }" ^
    "  }" ^
    "  if (-not $found) {" ^
    "    try {" ^
    "      $tcp = New-Object System.Net.Sockets.TcpClient;" ^
    "      $ar = $tcp.BeginConnect('127.0.0.1', $s.port, $null, $null);" ^
    "      $wait = $ar.AsyncWaitHandle.WaitOne(400, $false);" ^
    "      if ($wait -and $tcp.Connected) {" ^
    "        $results += [PSCustomObject]@{engine=$s.engine; version='auto'; host='127.0.0.1'; port=$s.port; service_name=''; is_active=$true; source='tcp_probe'; existing_schemas=@()};" ^
    "        $tcp.EndConnect($ar);" ^
    "      }" ^
    "      $tcp.Close();" ^
    "    } catch {}" ^
    "  }" ^
    "};" ^
    "if ($mode -eq '--json') {" ^
    "  ConvertTo-Json -InputObject @($results) -Compress:$false;" ^
    "} elseif ($mode -eq '--eval') {" ^
    "  if ($results.Count -gt 0) {" ^
    "    $first = $results[0];" ^
    "    Write-Output ('DETECTED_DB_COUNT=' + $results.Count);" ^
    "    Write-Output ('DETECTED_DB_ENGINE=' + $first.engine);" ^
    "    Write-Output ('DETECTED_DB_HOST=' + $first.host);" ^
    "    Write-Output ('DETECTED_DB_PORT=' + $first.port);" ^
    "    Write-Output ('DETECTED_DB_SOURCE=' + $first.source);" ^
    "  } else {" ^
    "    Write-Output 'DETECTED_DB_COUNT=0';" ^
    "  }" ^
    "} else {" ^
    "  if ($results.Count -gt 0) {" ^
    "    Write-Output ('[INFO] Discovered ' + $results.Count + ' active database instance(s).');" ^
    "    exit 0;" ^
    "  } else {" ^
    "    Write-Output '[INFO] No matching database instances discovered.';" ^
    "    exit 1;" ^
    "  }" ^
    "}"

exit /b %ERRORLEVEL%
