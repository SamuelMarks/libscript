@echo off
where ansible-galaxy >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  ansible-galaxy --version || echo ansible-galaxy found
) else (
  echo ansible-galaxy skipped (not found)
)
exit /b 0
