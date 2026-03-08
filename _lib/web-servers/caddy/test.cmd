@echo off
caddy version
if %errorlevel% neq 0 exit /b %errorlevel%
