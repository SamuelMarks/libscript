@echo off
mariadb --version
if %errorlevel% neq 0 exit /b %errorlevel%
