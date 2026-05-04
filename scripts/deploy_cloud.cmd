@echo off
setlocal
set "DIR=%~dp0.."
if defined LIBSCRIPT_ROOT_DIR set "DIR=%LIBSCRIPT_ROOT_DIR%"
call "%DIR%\_lib\cloud\core\deploy_cloud.cmd" %*
