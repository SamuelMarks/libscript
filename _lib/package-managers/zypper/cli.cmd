@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=zypper"
call "%~dp0\..\..\_common\component_core.cmd" %*
