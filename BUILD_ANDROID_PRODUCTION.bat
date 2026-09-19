@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
if errorlevel 1 exit /b 2

set "OLD_SLF_NO_PAUSE=%SLF_NO_PAUSE%"
set "SLF_NO_PAUSE=1"

echo ============================================================
echo Super Limeade Factory - build BOTH production APK and AAB
echo ============================================================
echo Requires external production signing environment variables.
echo.
call "%~dp0BUILD_APK_PRODUCTION.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :failed

call "%~dp0BUILD_AAB_PRODUCTION.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :failed

echo.
echo BOTH PRODUCTION BUILDS VERIFIED.
echo APK: %~dp0dist\local-apk\SLF-production.apk
echo AAB: %~dp0dist\local-aab\SLF-production.aab
goto :finish

:failed
echo.
echo ANDROID PRODUCTION BUILD FAILED with exit code %RC%.
echo Production signing is fail-closed; no signing secret is embedded in this package.

:finish
if defined OLD_SLF_NO_PAUSE (set "SLF_NO_PAUSE=%OLD_SLF_NO_PAUSE%") else (set "SLF_NO_PAUSE=")
if defined CI exit /b %RC%
echo.
pause
exit /b %RC%
