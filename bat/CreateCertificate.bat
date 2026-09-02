@echo off
cd..
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

:: Generate an untracked local development certificate only.
:: Production releases should use a separately generated private upload key.
if "%AND_CERT_PASS%"=="" set /P AND_CERT_PASS=[Choose local signing password]: 
if "%AND_CERT_PASS%"=="" goto failed

echo.
echo Generating a self-signed local Android packaging certificate
call adt -certificate -validityPeriod 25 -cn %AND_CERT_NAME% 2048-RSA "%AND_CERT_FILE%" %AND_CERT_PASS%
if errorlevel 1 goto failed

:succeed
echo.
echo Certificate created at: %AND_CERT_FILE%
echo Keep this file private. It is ignored by Git and its password is not printed.
echo.
goto end

:failed
echo.
echo Certificate creation FAILED.
echo.

:end
pause
