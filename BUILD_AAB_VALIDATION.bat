@echo off
setlocal EnableExtensions DisableDelayedExpansion

cd /d "%~dp0"
if errorlevel 1 (
  echo ERROR: Could not enter the repository directory.
  exit /b 2
)

where pwsh.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: PowerShell 7 ^(pwsh.exe^) is required.
  echo Install PowerShell 7, then run this BAT again.
  exit /b 2
)

echo Building Super Lemonade Factory validation AAB...
echo This uses a disposable, non-production signing certificate.
echo.
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build-aab.ps1" -Mode validation
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo VALIDATION AAB BUILD FAILED with exit code %RC%.
  exit /b %RC%
)

echo.
echo VALIDATION AAB BUILD VERIFIED.
echo Output: %~dp0dist\local-aab\SLF-validation.aab
echo Proof:  %~dp0dist\local-aab\validation-proof\
exit /b 0
