@echo off
setlocal EnableExtensions DisableDelayedExpansion

cd /d "%~dp0"
if errorlevel 1 (
  echo ERROR: Could not enter the source package directory.
  call :record_error "Could not enter the source package directory."
  call :maybe_pause
  exit /b 2
)

if not exist "dist\local-apk" mkdir "dist\local-apk" >nul 2>&1
if exist "dist\local-apk\LAST_BUILD_ERROR.txt" del /f /q "dist\local-apk\LAST_BUILD_ERROR.txt" >nul 2>&1

where pwsh.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: PowerShell 7 ^(pwsh.exe^) is required.
  call :record_error "PowerShell 7 (pwsh.exe) is required."
  call :maybe_pause
  exit /b 2
)

if not defined SLF_ANDROID_KEYSTORE (
  echo ERROR: SLF_ANDROID_KEYSTORE is not set.
  echo Set it to the external PKCS#12 production keystore path.
  call :record_error "SLF_ANDROID_KEYSTORE is not set."
  call :maybe_pause
  exit /b 2
)
if not exist "%SLF_ANDROID_KEYSTORE%" (
  echo ERROR: SLF_ANDROID_KEYSTORE does not point to an existing file.
  call :record_error "SLF_ANDROID_KEYSTORE does not point to an existing file."
  call :maybe_pause
  exit /b 2
)
if not defined SLF_ANDROID_KEYSTORE_PASSWORD (
  echo ERROR: SLF_ANDROID_KEYSTORE_PASSWORD is not set.
  call :record_error "SLF_ANDROID_KEYSTORE_PASSWORD is not set."
  call :maybe_pause
  exit /b 2
)
if not defined SLF_ANDROID_EXPECTED_CERT_SHA256 (
  echo ERROR: SLF_ANDROID_EXPECTED_CERT_SHA256 is not set.
  call :record_error "SLF_ANDROID_EXPECTED_CERT_SHA256 is not set."
  call :maybe_pause
  exit /b 2
)

echo Building Super Limeade Factory production APK...
echo The builder will fail closed unless the produced signer fingerprint matches the expected fingerprint.
echo No signing secret is stored by this BAT or written to proof metadata.
echo.
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build-aab-entry.ps1" -Mode production -Artifact apk
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo PRODUCTION APK BUILD FAILED with exit code %RC%.
  echo Error log: %~dp0dist\local-apk\LAST_BUILD_ERROR.txt
  if exist "%~dp0dist\local-apk\LAST_BUILD_ERROR.txt" type "%~dp0dist\local-apk\LAST_BUILD_ERROR.txt"
  call :maybe_pause
  exit /b %RC%
)

echo.
echo PRODUCTION APK BUILD VERIFIED.
echo Output: %~dp0dist\local-apk\SLF-production.apk
echo Proof:  %~dp0dist\local-apk\production-proof\
call :maybe_pause
exit /b 0

:record_error
if not exist "dist\local-apk" mkdir "dist\local-apk" >nul 2>&1
>"dist\local-apk\LAST_BUILD_ERROR.txt" echo error=%~1
exit /b 0

:maybe_pause
if defined CI exit /b 0
if /I "%SLF_NO_PAUSE%"=="1" exit /b 0
echo.
pause
exit /b 0
