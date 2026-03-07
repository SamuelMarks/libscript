@echo off
where deno >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  deno --version || echo deno found
) else (
  echo deno skipped (not found)
)
exit /b 0
