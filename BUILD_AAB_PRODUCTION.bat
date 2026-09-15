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
  echo The expected production signing certificate fingerprint is required.
  call :record_error "SLF_ANDROID_EXPECTED_CERT_SHA256 is not set."
  call :maybe_pause
  exit /b 2
)

call :bootstrap_tools
if errorlevel 1 (
  call :maybe_pause
  exit /b 2
)

echo Production AAB prerequisites are present.
echo The builder will fail closed unless the produced signer fingerprint matches the expected fingerprint.
echo No signing secret is stored by this BAT or written to proof metadata.
echo.
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build-aab-entry.ps1" -Mode production
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo PRODUCTION AAB BUILD FAILED with exit code %RC%.
  echo Error log: %~dp0dist\local-aab\LAST_BUILD_ERROR.txt
  if exist "%~dp0dist\local-aab\LAST_BUILD_ERROR.txt" (
    echo.
    type "%~dp0dist\local-aab\LAST_BUILD_ERROR.txt"
  )
  call :maybe_pause
  exit /b %RC%
)

echo.
echo PRODUCTION AAB BUILD VERIFIED.
echo Output: %~dp0dist\local-aab\SLF-production.aab
echo Proof:  %~dp0dist\local-aab\production-proof\
call :maybe_pause
exit /b 0

:bootstrap_tools
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "PATH=%JAVA_HOME%\bin;%PATH%"
if defined AIR_HOME if exist "%AIR_HOME%\bin\amxmlc.bat" if exist "%AIR_HOME%\bin\adt.bat" set "PATH=%AIR_HOME%\bin;%PATH%"
where amxmlc.bat >nul 2>&1
if not errorlevel 1 (
  where adt.bat >nul 2>&1
  if not errorlevel 1 exit /b 0
)
for %%D in ("C:\AIR_SDK" "C:\AIRSDK" "%USERPROFILE%\AIR_SDK" "%USERPROFILE%\AIRSDK" "%LOCALAPPDATA%\AIR_SDK") do (
  if exist "%%~D\bin\amxmlc.bat" if exist "%%~D\bin\adt.bat" (
    set "AIR_HOME=%%~D"
    set "PATH=%%~D\bin;%PATH%"
    exit /b 0
  )
)
echo ERROR: Adobe AIR SDK tools amxmlc/adt were not found.
echo Set AIR_HOME to your extracted HARMAN AIR SDK 51.3.4.3 folder, then run this BAT again.
call :record_error "Adobe AIR SDK tools amxmlc/adt were not found. Set AIR_HOME to the HARMAN AIR SDK 51.3.4.3 folder."
exit /b 2

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
