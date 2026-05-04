@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=kubernetes-k0s"
call "%~dp0\..\..\_common\component_core.cmd" %*
