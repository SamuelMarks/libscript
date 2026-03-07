@echo off
where ghcup >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  ghcup --version || echo ghcup found
) else (
  echo ghcup skipped (not found)
)
exit /b 0
