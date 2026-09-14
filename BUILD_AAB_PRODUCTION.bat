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
  exit /b 2
)

if not defined SLF_ANDROID_KEYSTORE (
  echo ERROR: SLF_ANDROID_KEYSTORE is not set.
  echo Set it to the external PKCS#12 production keystore path.
  exit /b 2
)
if not exist "%SLF_ANDROID_KEYSTORE%" (
  echo ERROR: SLF_ANDROID_KEYSTORE does not point to an existing file.
  exit /b 2
)
if not defined SLF_ANDROID_KEYSTORE_PASSWORD (
  echo ERROR: SLF_ANDROID_KEYSTORE_PASSWORD is not set.
  exit /b 2
)
if not defined SLF_ANDROID_EXPECTED_CERT_SHA256 (
  echo ERROR: SLF_ANDROID_EXPECTED_CERT_SHA256 is not set.
  echo The expected production signing certificate fingerprint is required.
  exit /b 2
)

echo Production AAB prerequisites are present.
echo The builder will fail closed unless the produced signer fingerprint matches the expected fingerprint.
echo No signing secret is stored by this BAT or written to proof metadata.
echo.
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build-aab.ps1" -Mode production
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo PRODUCTION AAB BUILD FAILED with exit code %RC%.
  exit /b %RC%
)

echo.
echo PRODUCTION AAB BUILD VERIFIED.
echo Output: %~dp0dist\local-aab\SLF-production.aab
echo Proof:  %~dp0dist\local-aab\production-proof\
exit /b 0
