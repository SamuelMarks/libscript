@echo off
setlocal EnableDelayedExpansion

:: ## Overview
:: Tests genuine Open edX Django execution by sending a heartbeat request to the LMS.
::
:: ## Usage
:: tests\test_openedx_genuine.cmd

set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

echo [INFO] Testing genuine Open edX Django execution...
set "_STARTED_SERVER=0"

powershell -NoProfile -Command "$res = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/heartbeat' -UseBasicParsing -ErrorAction SilentlyContinue; if ($res -and $res.StatusCode -eq 200) { exit 0 } else { exit 1 }"
if errorlevel 1 (
  echo [INFO] Open edX service not currently active. Launching genuine WSGI server on port 8000...
  start "OpenEdX_WSGI" /B python "%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\wsgi_server.py" --host 127.0.0.1 --port 8000 --cms-port 8001 >nul 2>&1
  set "_STARTED_SERVER=1"

  for /L %%i in (1,1,25) do (
    powershell -NoProfile -Command "$res = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/heartbeat' -UseBasicParsing -ErrorAction SilentlyContinue; if ($res -and $res.StatusCode -eq 200) { exit 0 } else { exit 1 }" >nul 2>&1
    if not errorlevel 1 goto heartbeat_ok
    powershell -NoProfile -Command "Start-Sleep -Milliseconds 200" >nul 2>&1
  )
)

:heartbeat_ok
powershell -NoProfile -Command "$res = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/heartbeat' -UseBasicParsing; if ($res.StatusCode -ne 200) { exit 1 }"
if errorlevel 1 (
  echo [ERROR] Open edX LMS heartbeat did not return 200 OK. >&2
  if "%_STARTED_SERVER%"=="1" taskkill /F /IM python.exe /T >nul 2>&1
  exit /b 1
)

if "%_STARTED_SERVER%"=="1" (
  taskkill /F /IM python.exe /T >nul 2>&1
)

echo [PASS] Genuine Open edX execution confirmed (HTTP 200 OK from /heartbeat).
exit /b 0
