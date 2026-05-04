@echo off
setlocal EnableDelayedExpansion
shift
call "%~dp0scripts\deploy_cloud.cmd" %*
goto :eof

