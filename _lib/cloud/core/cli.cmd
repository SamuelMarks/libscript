@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=core"
call "%~dp0\..\_common\component_core.cmd" %*
