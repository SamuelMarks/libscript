@echo off
lighttpd -v
if %errorlevel% neq 0 exit /b %errorlevel%