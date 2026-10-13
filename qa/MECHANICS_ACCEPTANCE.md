# Super Limeade Factory — representative mechanics acceptance matrix

**2026-10-13 owner clarification.** The purpose is to establish that the shipped game *works as intended*, not to write an infallible AI speedrunner or tune movement timings pixel-by-pixel. A representative real-input demonstration is sufficient for recurring mechanics unless regression evidence requires more.

## Evidence rules
- **OBSERVED**: genuine emulator inputs + actual rendered frames or read-only state response. Not merely an injected key or a green static unit test.
- **SOURCE/MAP**: source or authored level evidence, useful to choose tests but **not** a runtime PASS.
- **UNPROVEN**: no sufficiently direct evidence yet.
- Fail-closed when a game mechanic fails; do not call an uncompleted scripted route a product failure without distinguishing bad automation from faulty gameplay.
- Shipping Rev50 frozen; Rev52 candidate title is visually PASS but not Master-promoted. QA observer APK has a single read-only `PCPlayState.as` telemetry delta, and must not be used as sole final-release proof.
- No save edit, teleport, debug levelOver calls, synthetic unlock, physics or collision edits; no Play upload or publication.

## Test budget / representative cases

| Mechanic family | Representative scene | Evidence at current cutoff | Required for signoff |
|---|---|---|---|
| Startup, title typography, UI navigation | Rev52 title at 1920/2560, Warehouse level-select | Title screenshots PASS; Level2 selected through genuine UI | Verify new smoke Level1 selection |
| Andre move, sustained jump, action/dash | Level 1 tutorial | Action-specific smoke started, not yet adjudicated | One live ordinary-input motion/animation demonstration |
| Liselot move, switch, double jump | Level 1 tutorial | Prior natural progress by Liselot; double-jump implemented but independent response pending | One female movement & midair second-jump demonstration |
| Pushable small crate | Level 2 | **OBSERVED** fall left to x~714,y497 in real run 38464588882; other controller sequences pushed right. Game mechanic can work; route consistency is automation-quality issue | Do not repeat once satisfied absent product regression |
| Soldier patrol and collision/death | Level 2 | **OBSERVED** patrol traversed alive in 38461623946, died on guard in 38472669676; read-only patrol observer. | Already sufficient basic guard-collision demonstration |
| Spike hazard, recovery | Level 2/6 | Liselot performed natural jump over corridor to exit in 38464588882; death/revival mechanics still independent | One representative hazard/respawn check if needed |
| Piggyback and interaction/talk | Levels 3–4 | SOURCE/MAP instructions present, no live proof | Targeted real input proof (one of 3 or 4) |
| Checkpoint and restart | Level 5 (also 21–22, 25, 27, 30, 36) | SOURCE/MAP checkpoint objects and tutorial, no live respawn proof | One checkpoint→death→respawn example |
| Moving platform, triggered platform | Levels 1/13 | SOURCE/MAP; level 13 explicitly teaches landing-triggered movement | One moving and one triggered-platform observation |
| Collectible bottle/sugar/lives, persistence | Level 1 and Level 9 | SOURCE/MAP; level 9 explains collected bottle turns orange | One bottle+revisit or save/reload proof |
| Pause/resume and menu restart | Level 11 or any level | SOURCE/MAP Level 11 help prompt; separate Q5 workflows exist | One runtime demonstration or existing verified equivalent |
| Real level completion and unlock | Any representative naturally solved stage | Strict `levelFinished && levelOverMenu && both alive` classifier. No current natural Level2 win. | At least one real finish, Next Level transition, reopen/relaunch persistence |
| Factory chapter title, geometry, mechanic variety | Level 13 / sample 16–22 | SOURCE/MAP reviewed | Enter chapter normally; inspect, exercise at least one unique feature |
| Management chapter title, geometry, mechanic variety | Level 25 / sample 27–36 | SOURCE/MAP reviewed | Enter chapter normally; inspect, exercise at least one unique feature |
| Air dash | Level 32 | SOURCE/MAP explicit tutorial | One real airborne X/action response |
| Later-level breadth | Map definitions 1–36 sequentially scanned | SOURCE/MAP, representative mechanics recur | Representative load/render checks, not all levels cleared pixel-by-pixel |

## Active QA runs

- Original slow route runner `qa/rev52-observed-playthrough`: diagnostic source for prior successful mechanics; **not** a release readiness gate by itself. Repeated controller precision failures must not monopolize work.
- New separate branch `qa/gate2a-mechanics-coverage`: bounded, one-pass real-input mechanics smoke, run **38480810765** (verify outcome; currently queued/in progress at creation).
- Continue with new *mechanic classes* and normal progression verification, then stop once confidence is supported. Report any genuinely broken mechanic with a reproducible sequence and rendered evidence.

## Acceptance boundary

Do not claim "whole game verified" solely from source scans or one tutorial. Conversely, do not require a flawless 36-level bot when the owner's objective is a solid breadth audit. Distinguish **mechanics functionality**, **level loading/rendering**, **progression/persistence**, and **full campaign manual completion** as separate assertions.
