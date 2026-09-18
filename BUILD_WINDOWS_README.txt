SUPER LEMONADE FACTORY - WINDOWS SOURCE BUILD PACKAGE

QUICKEST TEST BUILD
Double-click:
  BUILD_ANDROID_VALIDATION.bat

That builds BOTH:
  dist\local-apk\SLF-validation.apk
  dist\local-aab\SLF-validation.aab

You may also build them separately:
  BUILD_APK_VALIDATION.bat
  BUILD_AAB_VALIDATION.bat

FIRST RUN
- PowerShell 7 (pwsh.exe) must already be installed.
- Missing Java 17, HARMAN AIR SDK 51.3.4.3, and Android SDK 36 tools are provisioned into a per-user local toolchain directory.
- HARMAN AIR and Android SDK downloads require explicit license acceptance.
- Validation builds use disposable non-production signing certificates.

PRODUCTION BUILDS
Use:
  BUILD_ANDROID_PRODUCTION.bat
or separately:
  BUILD_APK_PRODUCTION.bat
  BUILD_AAB_PRODUCTION.bat

Production builders fail closed unless these external environment variables are supplied:
  SLF_ANDROID_KEYSTORE
  SLF_ANDROID_KEYSTORE_PASSWORD
  SLF_ANDROID_EXPECTED_CERT_SHA256

No production signing secret is embedded in this source package.

FAILURE LOGS
APK: dist\local-apk\LAST_BUILD_ERROR.txt
AAB: dist\local-aab\LAST_BUILD_ERROR.txt

SOURCE IDENTITY
The package's gameplay/runtime source is pinned to the adaptive-touch + lime candidate:
  runtime commit 4255f0aae89ec9ef31ea16471858b1ec1c48d728
  runtime tree   372a480318cb475e62fb2bbbfe10665d52b10a0c

The surrounding source-package branch adds Windows build tooling only; it does not intentionally alter gameplay/runtime source beyond that runtime candidate.
