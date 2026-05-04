@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=pnpm"
call "%~dp0\..\..\_common\component_core.cmd" %*
