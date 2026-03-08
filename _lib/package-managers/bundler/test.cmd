@echo off
where bundler >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  bundler --version || echo bundler found
) else (
  echo bundler skipped (not found)
)
exit /b 0
