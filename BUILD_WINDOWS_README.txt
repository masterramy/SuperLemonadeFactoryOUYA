SUPER LIMEADE FACTORY - WINDOWS CORRESPONDING SOURCE BUILD PACKAGE

IDENTITY
Super Limeade Factory is an independent Android restoration/modification based
on the GPLv3-released OUYA source of Super Lemonade Factory by Shane Brouwer /
Initials Video Games. This Android edition is published by Ramy Baheeg and is
not produced, sponsored, or endorsed by Shane Brouwer or Initials Video Games.

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
- The supported release path remains HARMAN AIR's established free-tier path.
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

No production signing secret is embedded in this source package. Keep the
keystore and password outside the repository, source archive, CI, and Drive
release artifacts.

FAILURE LOGS
APK: dist\local-apk\LAST_BUILD_ERROR.txt
AAB: dist\local-aab\LAST_BUILD_ERROR.txt

CORRESPONDING SOURCE IDENTITY
The exact frozen product source represented by this package is:
  product commit 079a68ba800af3d15e97f140cc5ab1df7ce38332
  product tree   bf7ab61aa895310285b8d3aaf19c73786d664b0b

The source-package branch may add only source-distribution verification tooling
and this README around those frozen product bytes. The archive-mode builder
verifies the extracted source against the frozen public Git tree before building.

LICENSE / NOTICES
  LICENSE
  MODIFICATIONS.md
  SOURCE_DISCLOSURE.md
  THIRD_PARTY_NOTICES.md
  third_party\licenses\

PUBLIC CORRESPONDING-SOURCE REPOSITORY
  https://github.com/masterramy/SuperLemonadeFactoryOUYA
