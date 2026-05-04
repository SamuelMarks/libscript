@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=etcd"
call "%~dp0\..\..\_common\component_core.cmd" %*
