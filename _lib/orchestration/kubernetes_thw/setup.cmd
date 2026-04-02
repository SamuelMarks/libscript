@echo off
setlocal EnableDelayedExpansion
:: Source logging
if not defined LIBSCRIPT_ROOT_DIR set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."
set "LOG_CMD=%~dp0\..\..\_common\log.cmd"
if not exist "!LOG_CMD!" set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"
call "!LOG_CMD!" :log_warn "kubernetes_thw is not supported on Windows natively."
exit /b 0
