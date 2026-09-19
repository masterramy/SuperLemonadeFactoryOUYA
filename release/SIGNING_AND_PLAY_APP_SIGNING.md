# Production Signing and Play App Signing Procedure

## Non-negotiable boundary
Production signing material is externally owned by Ramy. Do **not** commit, upload, paste, archive, log, or place the private keystore/password in GitHub, Google Drive project artifacts, CI artifacts, or release documentation.

The production builders intentionally fail closed unless all required external inputs are present.

## Required local environment variables
Set these only in the trusted local Windows session used to create the production upload artifact:

`SLF_ANDROID_KEYSTORE`
: full path to the external PKCS#12 production/upload keystore

`SLF_ANDROID_KEYSTORE_PASSWORD`
: keystore password

`SLF_ANDROID_EXPECTED_CERT_SHA256`
: expected SHA-256 fingerprint of the signing certificate, 64 hex characters; separators are tolerated by the builder

## Verify the intended certificate before building
Use Java 17 `keytool` locally:

`keytool -list -v -storetype PKCS12 -keystore "C:\secure\path\upload-key.p12"`

Record the displayed SHA-256 certificate fingerprint outside the repository and set `SLF_ANDROID_EXPECTED_CERT_SHA256` to that value.

## Build both production artifacts
From the exact extracted release source package:

`BUILD_ANDROID_PRODUCTION.bat`

Or build the Play upload bundle only:

`BUILD_AAB_PRODUCTION.bat`

The AAB output is:

`dist\local-aab\SLF-production.aab`

The production builder verifies package name, version metadata, SDK levels, effective permission policy, archive contents, JAR signature validity, and exact signer SHA-256 fingerprint. A signer mismatch is a hard failure.

## Play App Signing
For a new Play app, use Play App Signing in the Console. Keep the **upload key** under Ramy's control and let Google manage the app-signing key used for APKs delivered to users.

Do not assume the Console's exact enrollment screen or key state in advance. After the developer-account transition settling period:
1. open the live app/signing setup;
2. confirm whether Play App Signing is already enabled or enrollment is required;
3. confirm the upload certificate shown by Google;
4. compare its SHA-256 fingerprint to the local upload key intended for this package;
5. only then create the final production-signed AAB;
6. independently verify the AAB signer fingerprint before upload.

If Google requires package-ownership or upload-key proof, follow the live Console instructions rather than improvising or exposing the private key.

## Publication boundary
Uploading/submitting/reviewing/starting a rollout is a separate human release gate. This procedure does not authorize any publication action.
