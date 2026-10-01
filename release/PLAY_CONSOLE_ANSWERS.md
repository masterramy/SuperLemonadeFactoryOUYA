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

The policy commit is documentation-only over exact Rev50. Before submission, independently confirm this URL opens without authentication from a normal public browser and remains active, non-geofenced, non-PDF, and non-editable. If Google rejects GitHub rendering as a policy host, move the same policy text to a durable public web page without changing the frozen game binary.

## Permissions
Expected effective Android permissions: **none**.
The release build must fail certification if any unexpected `uses-permission` appears, including `android.permission.INTERNET`.

## Target audience
**Final selection is an owner/Console decision and is not pre-certified by this dossier.**

Google's current Console uses separate target-age groups including Ages 13–15, Ages 16–17, and Ages 18 and over. Select only the group(s) the game was actually designed for and is appropriate for; do not add younger groups merely to broaden availability. A selection that includes children can trigger additional Families-policy obligations.

Current product evidence supports only these factual inputs to the decision:
- retro puzzle-platformer with text-heavy menus/story;
- no ads, account, social/UGC, chat, purchases, gambling, sexual content, or realistic violence;
- mild platforming peril / character death on environmental hazards;
- no child-directed design claim has been established.

Reconcile the exact live Console options and Ramy's intended audience immediately before saving the declaration.

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
Do not submit any form or release until:
1. the organization-account transition is complete;
2. at least 72 hours have elapsed from the actual transition-completion timestamp shown/confirmed by Google;
3. the live Console fields are reread and reconciled, including package registration/verification status;
4. the final target-audience choice has been owner-confirmed in the live Console;
5. the exact production-signed AAB has passed final cold audit;
6. Ramy explicitly approves submission.


## Current Google Play platform requirements — rechecked 2026-10-01

- New phone/tablet apps and updates submitted after 2026-08-31 must target Android 16 / API 36 or higher. This candidate targets API 36.
- After this developer account's transition to an organization account is complete, **wait at least 72 hours before submitting a new app** so Play systems can finish synchronizing the account-type change.
- Effective 2026-09-30, Play package-name registration is part of Android developer verification requirements. Before submission, confirm that `com.ramybaheeg.slfport` is registered or auto-registered in the live Console and complete any package-ownership proof Google actually requests.
- New apps use Play App Signing. Current Google documentation says new apps are automatically enrolled in quantum-ready hybrid signing with Google-generated app-signing keys; Ramy retains the upload key used to sign the AAB submitted to Play.
- Before submission, re-open **App content > Needs attention** and reconcile every live declaration. Do not assume this dossier's field names are still identical to the Console UI.
