@echo off
where bun >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  bun --version || echo bun found
) else (
  echo bun skipped (not found)
)
exit /b 0
