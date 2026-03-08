@echo off
minio --version
if %errorlevel% neq 0 exit /b %errorlevel%