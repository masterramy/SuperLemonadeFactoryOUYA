# Super Lemonade Factory Port

Super Lemonade Factory Port is an independent Android restoration/port of Super
Lemonade Factory built from the GPLv3-released OUYA source. This repository is the
public corresponding-source route for the Android port. It is not presented as an
official Initials publication or endorsement.

## Modification notice

Android restoration and modernization work for this publication line was performed
in **2026** by **Ramy Baheeg**. The Android-specific changes include current AIR/Android
packaging, modern SDK targeting, mobile input/display/runtime compatibility work,
privacy/source-disclosure surfaces, and release-integrity verification. The original
game remains credited to **Shane Brouwer / Initials**.

## License, credits, and source access

The source is distributed under **GNU GPL v3**; see `LICENSE`. The in-game Credits /
Port Info screen preserves the original credits, identifies this as an independent
Android port published by Ramy Baheeg, credits Shane Brouwer / Initials, and disclaims
official Initials publication or endorsement.

Public source repository:
`https://github.com/masterramy/SuperLemonadeFactoryOUYA`

For every distributed Android release, publish/preserve an immutable release tag (or
other immutable exact source reference), identify its Git commit SHA, preserve a source
archive route, and record the generated AAB SHA-256 so recipients can map the distributed
artifact to its exact corresponding source. Private signing keys/passwords are not
committed to the public source repository.

The Android privacy disclosure is in `privacy.html`.

## Reproducing the Android build

The release recipe is encoded in `.github/workflows/gate2a-android-release.yml`. The
current release toolchain is:

- Windows environment matching the release workflow;
- Java 17;
- HARMAN AIR SDK **51.3.4.3** (license accepted);
- Android SDK with compile/target SDK **36**;
- minimum Android SDK **21**;
- application descriptor `application.xml`;
- compiler config `obj/SLF_for_OuyaConfig.xml`.

From an exact checkout of the release commit/tag, compile the SWF with:

```cmd
amxmlc -load-config+=obj\SLF_for_OuyaConfig.xml -output=bin\SLFforOuya.swf
```

Package an Android App Bundle with AIR ADT using a developer-provided PKCS#12 signing
identity and the local Android SDK path:

```text
adt -package -target aab -storetype pkcs12 -keystore <keystore.p12> -storepass <password> dist/SLF-release.aab application.xml -C bin SLFforOuya.swf -C icons/android icons/icon_48.png icons/icon_57.png icons/icon_72.png icons/icon_96.png icons/icon_114.png icons/icon_144.png icons/icon_192.png -platformsdk <ANDROID_SDK_PATH>
```

The approved Android application ID is `com.ramybaheeg.slfport`; current release
version is `1.9` (`versionCode` `1009000`). The final release workflow must fail closed
unless the compiled AAB independently matches the approved application ID, versionName,
versionCode, min/target SDK values, effective permission policy (including no unexpected
`INTERNET` permission), and approved production signing certificate identity.

## Release verification

A release is not final merely because compilation or packaging succeeds. Preserve the
exact source SHA/tag, toolchain version, AAB SHA-256, compiled manifest proof, and signing
certificate fingerprint with the release evidence. Disposable QA/validation signing is
not production-signing proof.

## Restoration notes

The Android restoration modernizes the original OUYA/AIR project for current Android
packaging while preserving the game itself. Material Android-specific restoration
changes and exact release provenance are tracked in repository history and release
metadata. The shipping release must not use disposable QA signing material.
