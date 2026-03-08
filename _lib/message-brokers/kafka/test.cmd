@echo off
kafka-server-start.sh --version
if %errorlevel% neq 0 exit /b %errorlevel%