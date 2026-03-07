@echo off
where dash >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  dash --version || echo dash found
) else (
  echo dash skipped (not found)
)
exit /b 0
