@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=npm"
call "%~dp0\..\..\_common\component_core.cmd" %*
