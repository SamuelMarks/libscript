@echo off
where gradle >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  gradle --version || echo gradle found
) else (
  echo gradle skipped (not found)
)
exit /b 0
