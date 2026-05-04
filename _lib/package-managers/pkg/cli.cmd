@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=pkg"
call "%~dp0\..\..\_common\component_core.cmd" %*
