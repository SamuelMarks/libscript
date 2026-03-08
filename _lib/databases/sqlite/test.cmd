@echo off
sqlite3 --version
if %errorlevel% neq 0 exit /b %errorlevel%
