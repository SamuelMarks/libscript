@echo off
where vcpkg >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  vcpkg --version || echo vcpkg found
) else (
  echo vcpkg skipped (not found)
)
exit /b 0
