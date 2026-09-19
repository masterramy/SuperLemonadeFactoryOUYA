# Corresponding Source Disclosure

**Super Limeade Factory** is an independent Android restoration/modification based on the GPLv3-released OUYA source of **Super Lemonade Factory** by Shane Brouwer / Initials Video Games.

This Android edition is published by **Ramy Baheeg** and is not produced, sponsored, or endorsed by Shane Brouwer or Initials Video Games.

## Source location

Public repository:

https://github.com/masterramy/SuperLemonadeFactoryOUYA

The corresponding source for each distributed release must be preserved under an immutable Git commit/tag and as an exact source archive. The final release dossier records:

- exact source commit SHA;
- exact source tree SHA;
- source archive SHA-256 and byte count;
- exact Android artifact SHA-256 and byte count;
- toolchain versions and package metadata;
- signing-certificate fingerprint for the actual production upload artifact once production signing is performed.

## Build prerequisites

The supported Windows release tooling uses:

- PowerShell 7;
- Java 17;
- HARMAN AIR SDK 51.3.4.3 through the established free-tier path;
- Android SDK platform 36 and build-tools 36.0.0.

The source package includes one-click validation and production BAT entry points. Production signing intentionally fails closed unless externally held signing inputs and an expected certificate fingerprint are supplied.

## License material

- GNU GPL v3: `LICENSE`
- Modification notice: `MODIFICATIONS.md`
- Third-party notices: `THIRD_PARTY_NOTICES.md`
- Exact third-party grant texts: `third_party/licenses/`

Production signing secrets are not part of Corresponding Source and must never be committed or published.
