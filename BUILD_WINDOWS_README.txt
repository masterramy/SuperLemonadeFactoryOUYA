SUPER LIMEADE FACTORY - REV52 WINDOWS SOURCE BUILD PACKAGE

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
The package's original game/branding source is pinned to the exact Rev52 candidate:
  runtime commit 0d5fd0bb63558ad6659ba31552deaede4745382b
  runtime tree   ba0cfae73f758b3d4c9157e1e496357faf59acda

The surrounding source-package branch adds Windows build tooling only; it does not intentionally alter gameplay/runtime source beyond that runtime candidate.

REV52 LOCAL ARCHIVE PROVENANCE FIX (October 14, 2026)
The base Rev52 source ZIP retained obsolete builder source-tree pins.
This independent QA release-tooling branch corrects only the local build wrapper
and its readme; original gameplay, level assets, save behavior and app ID
are UNCHANGED. The archive builder verifies all other original Rev52 tracked
blobs remotely against GitHub's immutable commit tree before producing an AAB.
Only a PRODUCTION-signed AAB with the owner-held UPLOAD certificate may go to Play.
Do NOT upload disposable validation AABs to Google Play.
No production release or public rollout is authorized by this tooling correction.
