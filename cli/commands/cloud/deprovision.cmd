@echo off
setlocal EnableDelayedExpansion
shift
call "%~dp0scripts\teardown_cloud.cmd" %*
goto :eof


