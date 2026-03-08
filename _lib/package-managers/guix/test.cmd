@echo off
where guix >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  guix --version || echo guix found
) else (
  echo guix skipped (not found)
)
exit /b 0
