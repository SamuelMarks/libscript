@echo off
where winget >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  winget --version || echo winget found
) else (
  echo winget skipped (not found)
)
exit /b 0
