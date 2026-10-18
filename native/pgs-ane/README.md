# Native Google Play Games v2 Saved Games — source integration

This is **real Android SDK source**, not a simulated API or functioning production integration. The independent Java `FREExtension` implements the exact ActionScript `PGSNativeTransport` function/event contract, with PGSv2 `GamesSignInClient`, `SnapshotsClient`, manual conflict detection, read-before-write compare, and fail-closed errors. The source itself is not a compiled, installed `.ane` and does not prove Google account authentication.

## Required before enabled

1. Compile against Harman AIR `FlashRuntimeExtensions.jar` and `com.google.android.gms:play-services-games-v2:22.1.0` with all transitive dependencies resolved through an Android-native Gradle build. Google Play Services v2 dependencies must be bundled in the ANE under AIR's supported dependency packaging mechanism. Do not copy Maven dependencies partially or confuse a `.jar` with a complete `.ane`.
2. Supply `extension.xml`, `platform.xml` / Android manifest and AIR Android platform packaging for extension ID `com.ramybaheeg.slfport.pgs.savedgames`. The application must declare `com.google.android.gms.games.APP_ID` from the actual Play Console PGS app, include Internet permission, and have OAuth Android client SHA-1 plus package configured. **No app identifier or Google credentials are invented here.** The disposable `.dev` certificate differs every build; those builds will generally fail Play Games OAuth until a dedicated QA client is registered.
3. When the ANE truly packages/links, set up a separate isolated signing/profile environment, add extension ID to the *future development descriptor only*, compile with `adt -extdir`, and test on two real signed-in Android devices. Observe manual conflicts, offline errors and restore. Do not enable in frozen v1.9.1.
4. Verify that the `PlayGamesSdk.initialize` call occurs only after the player presses Cloud Save. This extension has no automatic network sign-in on creation. The native source uses explicit `GamesSignInClient.signIn()` only when requested.

## API contract and caveats

The provider replies via `dispatchStatusEventAsync("PGS", JSON)` where JSON includes operation, the originating uint requestId and success/empty/conflict/error status. No user ID/token is sent to ActionScript. An unexpected stale result is ignored by the AS3 request-ID gate.

Write is gated by an immediately preceding read and byte-level optimistic comparison to avoid blind overwrites; on changed remote data it returns conflict so `CloudSyncCoordinator` can re-fetch/re-merge. However Google server-side races and offline consistency require real two-device test proof. `commitAndClose` success is a Google SDK task completion, not proof of externally observed restore without the test.

Google SDK official references: https://developer.android.com/games/pgs/android/migrate-to-v2 ; https://developers.google.com/android/reference/com/google/android/gms/games/SnapshotsClient .

## Build gate

This Gradle module is source and library-dependency preparation only. An Android `.aar` is **not** a distributable AIR `.ane`. Packaging all Google Play services transitive Android dependencies into valid AIR extension native/platform descriptors requires a confirmed AIR SDK workflow; until that happens, extension remains absent from application.xml and `supported()` remains false.

Native Java source: `src/main/java/com/ramybaheeg/slfport/pgs/PGSExtension.java`.
