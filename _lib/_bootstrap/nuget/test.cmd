@echo off
where nuget >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  nuget help || echo nuget found
) else (
  echo nuget skipped (not found)
)
exit /b 0
