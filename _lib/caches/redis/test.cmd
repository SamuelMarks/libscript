@echo off
redis-server --version
if %errorlevel% neq 0 exit /b %errorlevel%