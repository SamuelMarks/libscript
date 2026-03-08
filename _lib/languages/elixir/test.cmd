@echo off
elixir --version
if %errorlevel% neq 0 exit /b %errorlevel%
