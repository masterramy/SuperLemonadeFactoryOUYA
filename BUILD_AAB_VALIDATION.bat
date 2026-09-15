@echo off
setlocal EnableExtensions DisableDelayedExpansion

cd /d "%~dp0"
if errorlevel 1 (
  echo ERROR: Could not enter the source package directory.
  call :record_error "Could not enter the source package directory."
  call :maybe_pause
  exit /b 2
)

if not exist "dist\local-aab" mkdir "dist\local-aab" >nul 2>&1
if exist "dist\local-aab\LAST_BUILD_ERROR.txt" del /f /q "dist\local-aab\LAST_BUILD_ERROR.txt" >nul 2>&1

where pwsh.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: PowerShell 7 ^(pwsh.exe^) is required.
  echo Install PowerShell 7, then run this BAT again.
  call :record_error "PowerShell 7 (pwsh.exe) is required."
  call :maybe_pause
  exit /b 2
)

echo Building Super Lemonade Factory validation AAB...
echo This uses a disposable, non-production signing certificate.
echo.
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build-aab-entry.ps1" -Mode validation
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo VALIDATION AAB BUILD FAILED with exit code %RC%.
  echo Error log: %~dp0dist\local-aab\LAST_BUILD_ERROR.txt
  if exist "%~dp0dist\local-aab\LAST_BUILD_ERROR.txt" (
    echo.
    type "%~dp0dist\local-aab\LAST_BUILD_ERROR.txt"
  )
  call :maybe_pause
  exit /b %RC%
)

echo.
echo VALIDATION AAB BUILD VERIFIED.
echo Output: %~dp0dist\local-aab\SLF-validation.aab
echo Proof:  %~dp0dist\local-aab\validation-proof\
call :maybe_pause
exit /b 0

:record_error
if not exist "dist\local-aab" mkdir "dist\local-aab" >nul 2>&1
>"dist\local-aab\LAST_BUILD_ERROR.txt" echo error=%~1
exit /b 0

:maybe_pause
if defined CI exit /b 0
if /I "%SLF_NO_PAUSE%"=="1" exit /b 0
echo.
pause
exit /b 0
