@echo off
zig version
if %errorlevel% neq 0 exit /b %errorlevel%
