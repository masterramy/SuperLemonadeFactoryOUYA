# Google Play Console Answers — Super Limeade Factory

These answers are release-candidate declarations. Binary-derived answers must be rechecked against the exact final production-signed AAB before submission, and the Console itself must be reconciled after the account transition settling period.

## Identity
- App name: **Super Limeade Factory**
- Package: **com.ramybaheeg.slfport**
- Planned publisher identity: **Ramy Baheeg**
- Final public Play developer/entity display: **reconcile from the live Console after the personal-to-organization account transition; do not guess or overwrite the live account identity**
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
Public policy file:
https://github.com/masterramy/SuperLemonadeFactoryOUYA/blob/gate2a-rev47-super-limeade-release-ready/privacy.html

Before submission, reconcile this URL against the final immutable release branch/tag or other durable public hosting route and confirm it opens without authentication.

## Permissions
Expected effective Android permissions: **none**.
The release build must fail certification if any unexpected `uses-permission` appears, including `android.permission.INTERNET`.

## Target audience
**Owner decision required in the live Play Console. Do not preselect this field autonomously.**

Evidence for Ramy's decision:
- the game is a retro puzzle-platformer, not designed primarily for children;
- it has no ads, accounts, social features, purchases, or data collection;
- it contains mild non-graphic platforming peril / character death and military/factory story references;
- current Play audience controls may present separate age buckets rather than one combined range.

Ramy must choose the intended audience buckets after reviewing the live Console wording. Do not opt into child-directed/Families treatment merely to broaden availability, and do not infer an age selection from this dossier.

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
2. the documented Google synchronization/settling interval has elapsed;
3. the live Console fields are reread and reconciled;
4. the exact production-signed AAB has passed final cold audit;
5. Ramy explicitly approves submission.


## Current Google Play platform requirements — verified 2026-09-19

- New phone/tablet apps and updates submitted after 2026-08-31 must target Android 16 / API 36 or higher. This candidate targets API 36.
- After this developer account's transition to an organization account is complete, **wait at least 72 hours before submitting a new app** so Play systems can finish synchronizing the account-type change.
- Effective 2026-09-30, Play package-name registration is part of Android developer verification requirements. Before submission, confirm that `com.ramybaheeg.slfport` is registered or auto-registered in the live Console and complete any package-ownership proof Google actually requests.
- New apps use Play App Signing. Current Google documentation says new apps are automatically enrolled in quantum-ready hybrid signing with Google-generated app-signing keys; Ramy retains the upload key used to sign the AAB submitted to Play.
- Before submission, re-open **App content > Needs attention** and reconcile every live declaration. Do not assume this dossier's field names are still identical to the Console UI.
