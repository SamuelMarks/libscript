@echo off
fluent-bit --version
if %errorlevel% neq 0 exit /b %errorlevel%