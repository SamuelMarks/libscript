@echo off
where rye >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  rye --version || echo rye found
) else (
  echo rye skipped (not found)
)
exit /b 0
