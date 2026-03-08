@echo off
gitea --version
if %errorlevel% neq 0 exit /b %errorlevel%