@echo off
where gem >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  gem --version || echo gem found
) else (
  echo gem skipped (not found)
)
exit /b 0
