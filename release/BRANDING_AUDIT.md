# Super Limeade Factory — Branding / Attribution Audit

## Release identity

**Current public edition name:** Super Limeade Factory  
**Publisher of this Android edition:** Ramy Baheeg  
**Package:** `com.ramybaheeg.slfport`  
**Relationship to original work:** independent GPLv3-based Android restoration/modification of *Super Lemonade Factory* by Shane Brouwer / Initials Video Games.  
**Endorsement status:** no endorsement or permission is claimed or implied. Silence or non-response from the original developer is not treated as consent.

## Current product-facing identity

The Android application descriptor, window title, in-game title logo, launcher icon family, credits/port information, privacy/about page, relevant story text, save-file label, and release/store copy use **Super Limeade Factory**.

The lime treatment preserves the original pixel-art sign silhouette while changing the public edition's sign color and edition-name text.

## Residual original-title references — allowed classifications

A release audit intentionally permits the original title **Super Lemonade Factory** only where its presence is necessary to describe source history or attribution.

### Required historical attribution / provenance

- `src/PCCreditsState.as`: identifies the GPLv3-released original source and original developer.
- `src/PCPrivacyState.as`: identifies the source work while explicitly stating independent publication / no endorsement.
- `README.md`, `MODIFICATIONS.md`, `SOURCE_DISCLOSURE.md`, `privacy.html`, and release documentation: provenance, license, policy, and no-affiliation disclosures.

These references are **intentional and required context**, not public-brand residue.

### Source/development-history references

Historical Ogmo project metadata and source-development documentation retain original project names such as:

- `data/SLF_levelEditor/PC/_SuperLemonadeFactoryPC.oep`
- other Ogmo / editor project-name files
- historical source/editor instructions

These files are not presented as the Android edition's public title. Renaming them would add needless source-history churn and could damage tooling/provenance.

### Technical compatibility names

Names such as `SLFforOuya.swf`, OUYA-related class/package paths, old workflow labels, and compatibility-provider references are technical lineage/build identifiers. They are not public publisher or endorsement claims and are retained where changing them would be unnecessary or risky.

## Removed unacceptable public-brand residue

The release-preparation branch removes or replaces old-brand residue from:

- AIR application name / filename / window title;
- in-game title logo;
- Android launcher / Play icon family;
- store-facing feature graphic;
- public story/dialogue references to the factory name;
- save-file UI;
- legacy “Initials Video Games Presents” presentation line;
- Windows build-script display copy.

## Automated enforcement

The exact-head release audit scans runtime source/data and fails if **Super Lemonade Factory** or **Lemonade Factory** appears in reachable runtime content outside the explicit attribution/disclaimer surfaces and the classified source-only project/logo documentation.

It separately fails on legacy public-presentation phrases such as **“Initials Video Games Presents”** or **“Super Lemonade Factory Port.”**

## Result at Rev47 release-audit Run 35428117541

The static branding audit passed for source head `e2b60a72608bb58a08d10a435fa9067dea69c019` / tree `505408c21bc24a0f0092634695ca00906ab10608`.

Later release-source mutations must rerun this audit before a READY TO PUBLISH claim.
