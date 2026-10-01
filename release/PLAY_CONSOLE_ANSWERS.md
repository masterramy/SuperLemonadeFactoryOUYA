# Google Play Console Answers — Super Limeade Factory

These answers are release-candidate declarations. Binary-derived answers must be rechecked against the exact final production-signed AAB before submission, and the Console itself must be reconciled after the account transition settling period.

## Identity
- App name: **Super Limeade Factory**
- Package: **com.ramybaheeg.slfport**
- Publisher shown publicly: **Ramy Baheeg**
- Category: **Game — Puzzle**
- Original-work attribution: Super Lemonade Factory by Shane Brouwer / Initials Video Games
- Affiliation statement: independent Android restoration/modification; not produced, sponsored, or endorsed by the original developer

## Ads
**No.** The application contains no advertising SDK or advertising surface.

## App access
**All functionality is available without special access.**
No login, membership, invitation, subscription, geographic entitlement, or reviewer credential is required.

## Data Safety
Current code/binary contract:
- Data collected: **No**
- Data shared with third parties: **No**
- Advertising data: **No**
- Analytics: **No**
- Account data: **No**
- Location: **No**
- Contacts: **No**
- Financial information: **No**
- Health/fitness data: **No**
- Messages/photos/files: **No**
- Device identifiers used by the app: **No**
- Server-side user data retention: **None**

Game progress is stored locally in app-private storage and is not transmitted to Ramy Baheeg.

## Account creation and account deletion
- Does the app let users create an account? **No**
- Account-deletion URL requirement: **Not applicable because the app does not create user accounts.**
- Remote user-data deletion workflow: **Not applicable; the app retains no server-side user data.**
- Local progress can be removed by clearing app data or uninstalling the app.

## Privacy policy
Current immutable policy candidate:
https://github.com/masterramy/SuperLemonadeFactoryOUYA/blob/2894a522e609d7d9f7d4c54b9adb85ec7f61f064/PRIVACY.md

The URL is commit-pinned so the referenced policy bytes cannot change in place. Before entering it in Play Console, verify the rendered page opens anonymously and remains globally accessible/non-geofenced. Google Play requires a publicly accessible, non-editable privacy-policy URL and also requires privacy policy text or a link within the app.

## Permissions
Expected effective Android permissions: **none**.
The release build must fail certification if any unexpected `uses-permission` appears, including `android.permission.INTERNET`.

## Target audience
Current Play age-group choices separate teens into **13–15**, **16–17**, and **18+**.

Do not select age groups merely to broaden availability. Google says any selected audience that includes children triggers Families-policy obligations, and notes that the 13–15 and 16–17 groups may be considered children in some locales. The final Console selection is therefore an owner/legal-policy judgment and must be reconciled against the live form.

Product evidence relevant to that choice: the game has no ads, analytics, accounts, online communication, data transmission, IAP, gambling, sexual content, or realistic/graphic violence; it does contain retro platforming peril, character death on environmental hazards, and wartime/factory narrative context.

## Content-rating questionnaire evidence
Answer from the actual game content, not from branding:
- Graphic/realistic violence: **No**
- Blood/gore: **No**
- Sexual content/nudity: **No**
- Gambling/simulated gambling: **No**
- Controlled substances: **No**
- User-generated content: **No**
- Online communication between users: **No**
- Location sharing: **No**
- In-app purchases: **No**
- Mild platforming peril / character death on environmental hazards: **Yes, where the questionnaire asks about non-graphic/fantasy or mild violence/peril.**
- Military/factory story references: **Yes as narrative context where asked; not realistic combat simulation.**

The IARC rating itself must be the result returned by the live questionnaire; do not invent a rating label in advance.

## App content / policy forms
- News app: **No**
- Government app: **No**
- Financial features: **No**
- Health features: **No**
- Social/dating features: **No**
- App access restrictions: **No**
- Ads: **No**
- Sensitive/high-risk permissions: **None expected**
- Account creation: **No**

## Submission hold
Organization transition and production access are owner-confirmed complete. Before submission:
1. confirm any required post-transition synchronization interval has actually elapsed from the live account event;
2. reread and reconcile every live Console field and package-registration requirement;
3. reconcile Play App Signing / upload-certificate identity;
4. create and cold-audit the exact production-signed AAB;
5. complete physical-device and Play-delivered smoke testing;
6. obtain Ramy's explicit submission approval.


## Current Google Play platform requirements — verified 2026-09-19

- New phone/tablet apps and updates submitted after 2026-08-31 must target Android 16 / API 36 or higher. This candidate targets API 36.
- After this developer account's transition to an organization account is complete, **wait at least 72 hours before submitting a new app** so Play systems can finish synchronizing the account-type change.
- Effective 2026-09-30, Play package-name registration is part of Android developer verification requirements. Before submission, confirm that `com.ramybaheeg.slfport` is registered or auto-registered in the live Console and complete any package-ownership proof Google actually requests.
- New apps use Play App Signing. Current Google documentation says new apps are automatically enrolled in quantum-ready hybrid signing with Google-generated app-signing keys; Ramy retains the upload key used to sign the AAB submitted to Play.
- Before submission, re-open **App content > Needs attention** and reconcile every live declaration. Do not assume this dossier's field names are still identical to the Console UI.


## Rev50 Play static preflight — 2026-10-01

QA-only branch `qa/rev50-release-qualification` introduced no shipping-source delta and re-used the exact promoted Rev50 artifacts.

Run `36832587344`: SUCCESS.
Verified against exact Rev50 AAB SHA-256 `7652669e33fd8dacb9cba902adc12eef31cb32f717e60ccf320310f9d83a8461`:
- BundleConfig native-library uncompression enabled;
- 16 KiB page alignment configuration present;
- native PT_LOAD alignment minimum >= 0x4000;
- ABIs present: armeabi-v7a, arm64-v8a, x86, x86_64;
- active network call sites: none in frozen release audit;
- source permission references: none in frozen release audit;
- Play icon: 512x512;
- feature graphic: 1024x500.

This is static preflight evidence only. It does not substitute for Play Console processing, Pre-launch Report, physical-device acceptance, production signing, or Play-delivered install testing.


## Final autonomous Rev50 release qualification — 2026-10-01

Rendered touch qualification:
- workflow run `36887620530`, attempt 2: SUCCESS
- QA workflow head: `dc182008fd091930218a55eef854a548750172b4`
- exact promoted x64 APK SHA-256 verified: `90fde292caacbeb5cb68aa0d56c9672808e0aadd55c719c3b1b65e688440998c`
- shipping-source delta vs Rev50: none
- evidence artifact: `11174644888`, digest `sha256:6f2cdb38c9afe9ae52ee8889e58df790a214ffa89e3940035942a4c1206aac8c`
- sequential rendered review: main menu PASS; fresh Level 1 selection PASS; real-touch swipe navigation to Level 3 PASS; locked-Level-3 modal PASS; real-touch modal dismissal PASS; real-touch navigation to Level 2 PASS; actual Level 2 gameplay PASS; fatal-runtime evidence absent.

Play/static + progression-source qualification:
- workflow run `36888659627`: SUCCESS
- QA workflow head: `86b50a9c524e2b5bbc604f1488b22f43e1d277b9`
- evidence artifact: `11176465073`, digest `sha256:7fec9747f8d61007ecdf1142fbfce0e8d34c5f5157ed04507d2aa20ac6a53aaa`
- exact promoted Rev50 AAB SHA-256 reverified
- API/ABI/page-alignment/network/permission/store-graphic checks PASS
- completion-to-unlock source invariant PASS: fresh normal progress unlocks Levels 1–2; genuine Level 2 completion writes the Level 3 progress slot; `FlxSave.close()` flushes the backing SharedObject; Level Select reloads the same array and gates Level 3 from that slot.

Boundary: this static invariant does **not** claim that the automated harness genuinely completed the full Level 2 puzzle. That runtime-completion residual remains UNPROVEN, not failed and not product RED.
