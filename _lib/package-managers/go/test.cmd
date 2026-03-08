@echo off
where go >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  go version || echo go found
) else (
  echo go skipped (not found)
)
exit /b 0
