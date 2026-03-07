@echo off
where asdf >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  asdf --version || echo asdf found
) else (
  echo asdf skipped (not found)
)
exit /b 0
