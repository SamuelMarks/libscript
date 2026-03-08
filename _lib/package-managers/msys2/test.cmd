@echo off
where msys2 >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  msys2 --version || echo msys2 found
) else (
  echo msys2 skipped (not found)
)
exit /b 0
