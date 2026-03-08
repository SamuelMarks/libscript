@echo off
gitlab-ctl status
if %errorlevel% neq 0 exit /b %errorlevel%