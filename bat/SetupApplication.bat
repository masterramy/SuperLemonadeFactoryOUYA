:user_configuration

:: About AIR application packaging
:: http://livedocs.adobe.com/flex/3/html/help.html?content=CommandLineTools_5.html#1035959
:: http://livedocs.adobe.com/flex/3/html/distributing_apps_4.html#1037515

:: NOTICE: all paths are relative to project root

:: Android packaging
:: Production signing material must not live in Git. Set these environment
:: variables to point at a private local PKCS#12 keystore when packaging locally:
::   SLF_ANDROID_KEYSTORE
::   SLF_ANDROID_KEYSTORE_PASSWORD
set AND_CERT_NAME="Super Lemonade Factory"
set AND_CERT_FILE=cert\release-signing.p12
if not "%SLF_ANDROID_KEYSTORE%"=="" set AND_CERT_FILE=%SLF_ANDROID_KEYSTORE%
set AND_CERT_PASS=%SLF_ANDROID_KEYSTORE_PASSWORD%
set AND_ICONS=icons/android

set AND_SIGNING_OPTIONS=-storetype pkcs12 -keystore "%AND_CERT_FILE%"
if not "%AND_CERT_PASS%"=="" set AND_SIGNING_OPTIONS=%AND_SIGNING_OPTIONS% -storepass %AND_CERT_PASS%

:: iOS packaging
set IOS_DIST_CERT_FILE=
set IOS_DEV_CERT_FILE=
set IOS_DEV_CERT_PASS=
set IOS_PROVISION=cert\Super Lemonade Factory.mobileprovision
set IOS_ICONS=icons/ios

set IOS_DEV_SIGNING_OPTIONS=-storetype pkcs12 -keystore "%IOS_DEV_CERT_FILE%" -storepass %IOS_DEV_CERT_PASS% -provisioning-profile %IOS_PROVISION%
set IOS_DIST_SIGNING_OPTIONS=-storetype pkcs12 -keystore "%IOS_DIST_CERT_FILE%" -provisioning-profile %IOS_PROVISION%

:: Application descriptor
set APP_XML=application.xml

:: Files to package
set APP_DIR=bin
set FILE_OR_DIR=-C %APP_DIR% .

:: Your application ID (must match <id> of Application descriptor)
set APP_ID=com.initialsgames.SLF

:: Output packages
set DIST_PATH=dist
set DIST_NAME=Super Lemonade Factory

:: Debugging using a custom IP
set DEBUG_IP=



:validation
%SystemRoot%\System32\find /C "<id>%APP_ID%</id>" "%APP_XML%" > NUL
if errorlevel 1 goto badid
goto end

:badid
echo.
echo ERROR: 
echo   Application ID in 'bat\SetupApplication.bat' (APP_ID) 
echo   does NOT match Application descriptor '%APP_XML%' (id)
echo.

:end