@echo off
where flatpak >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  flatpak --version || echo flatpak found
) else (
  echo flatpak skipped (not found)
)
exit /b 0
