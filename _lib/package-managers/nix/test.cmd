@echo off
where nix >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  nix --version || echo nix found
) else (
  echo nix skipped (not found)
)
exit /b 0
