@echo off
setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd" :assert_version celery "."
