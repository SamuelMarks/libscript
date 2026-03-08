@echo off
set "PATH=%PATH%;C:\Program Files\fluent-bit\bin"
fluent-bit --version
if %errorlevel% neq 0 exit /b %errorlevel%