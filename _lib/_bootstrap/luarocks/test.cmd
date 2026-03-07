@echo off
where luarocks >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  luarocks --version || echo luarocks found
) else (
  echo luarocks skipped (not found)
)
exit /b 0
