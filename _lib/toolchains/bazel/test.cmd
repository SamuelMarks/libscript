@echo off
bazel --version
if %errorlevel% neq 0 exit /b %errorlevel%