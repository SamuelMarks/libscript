@echo off
where dnf >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  dnf --version || echo dnf found
) else (
  echo dnf skipped (not found)
)
exit /b 0
