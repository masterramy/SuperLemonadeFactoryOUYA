@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
if errorlevel 1 exit /b 2

set "OLD_SLF_NO_PAUSE=%SLF_NO_PAUSE%"
set "SLF_NO_PAUSE=1"

echo ============================================================
echo Super Lemonade Factory - build BOTH validation APK and AAB
echo ============================================================
echo.
call "%~dp0BUILD_APK_VALIDATION.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :failed

call "%~dp0BUILD_AAB_VALIDATION.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :failed

echo.
echo BOTH VALIDATION BUILDS VERIFIED.
echo APK: %~dp0dist\local-apk\SLF-validation.apk
echo AAB: %~dp0dist\local-aab\SLF-validation.aab
goto :finish

:failed
echo.
echo ANDROID VALIDATION BUILD FAILED with exit code %RC%.
echo Check dist\local-apk\LAST_BUILD_ERROR.txt and dist\local-aab\LAST_BUILD_ERROR.txt.

:finish
if defined OLD_SLF_NO_PAUSE (set "SLF_NO_PAUSE=%OLD_SLF_NO_PAUSE%") else (set "SLF_NO_PAUSE=")
if defined CI exit /b %RC%
echo.
pause
exit /b %RC%
