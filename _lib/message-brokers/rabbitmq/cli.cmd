@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=rabbitmq"
call "%~dp0\..\..\_common\component_core.cmd" %*
