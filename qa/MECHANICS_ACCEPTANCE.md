# Super Limeade Factory — representative mechanics acceptance matrix

**2026-10-13 owner clarification.** The purpose is to establish that the shipped game *works as intended*, not to write an infallible AI speedrunner or tune movement timings pixel-by-pixel. A representative real-input demonstration is sufficient for recurring mechanics unless regression evidence requires more.

## Evidence rules
- **OBSERVED**: genuine emulator inputs + actual rendered frames or read-only state response. Not merely an injected key or a green static unit test.
- **SOURCE/MAP**: source or authored level evidence, useful to choose tests but **not** a runtime PASS.
- **UNPROVEN**: no sufficiently direct evidence yet.
- Fail-closed when a game mechanic fails; do not call an uncompleted scripted route a product failure without distinguishing bad automation from faulty gameplay.
- Shipping Rev50 frozen; Rev52 candidate title is visually PASS but not Master-promoted. QA observer APK has a single read-only `PCPlayState.as` telemetry delta, and must not be used as sole final-release proof.
- No save edit, teleport, debug levelOver calls, synthetic unlock, physics or collision edits; no Play upload or publication.

## Sequential real-run review (evidence reuse, not a new bot claim)

Run **38464588882**, artifact **11848391661** was read end-to-end: **25 timestamped state records**, from real Level 2 gameplay start through the final stalled tall-wall attempt. Critical ordered observations: player2 x580→730→801→991→1380→1314 (genuine navigation), crate x763→842→714 and y377→497 (a legitimate leftward fall), Andre y479→382 during held jump, then x210→250→288→558→730 through the soldier section, all with dead flags false in this run. Later wall ascent remained incomplete; `levelFinished=false`, `levelOverMenu=false` throughout. Earlier separate run 38472669676 observed a real guard death at x494 with army x489. **These are mechanic-specific evidence, not full-level qualification.**

The independent new Level 1 smoke attempts **38480810765**, **38481259245**, **38481655023** stopped in UI selection/cinematic classification. No game-mechanic failure occurred; **do not spend more emulator runs on button-coordinate or cutscene-classifier tuning as a release gate**. Reserve future runtime testing for currently uncovered mechanic families and authentic exit/unlock/persistence proof.

## Test budget / representative cases

| Mechanic family | Representative scene | Evidence at current cutoff | Required for signoff |
|---|---|---|---|
| Startup, title typography, UI navigation | Rev52 title at 1920/2560, Warehouse level-select | Title screenshots PASS; Level2 selected through genuine UI | Title/Level2 UI already old real-touch proved; isolated Level1 via QA hook now runtime observed but NATURAL Level1 launch remains separate |
| Andre move, sustained jump, air dash | Level 2 | **OBSERVED** in real run38464588882 (x210→558; y479→382→439→399 during guard jump/dash); large-crate destruction still unproven | Only targeted breakable-crate test remains |
| Liselot movement, switch, airborne leap | Level 2 | **OBSERVED** x580→1380→1314 across corridor; separately controlled from Andre; second-airborne-jump activation specifically still unproven | Direct second airborne upward-velocity impulse observed in QA isolated Level1 CI38490845197; exact-shipping/device parity remains |
| Pushable small crate | Level 2 | **OBSERVED** fall left to x~714,y497 in real run 38464588882; other controller sequences pushed right. Game mechanic can work; route consistency is automation-quality issue | Do not repeat once satisfied absent product regression |
| Soldier patrol and collision/death | Level 2 | **OBSERVED** patrol traversed alive in 38461623946, died on guard in 38472669676; read-only patrol observer. | Already sufficient basic guard-collision demonstration |
| Spike hazard, recovery | Level 2/6 | **OBSERVED** Liselot crossed hazard corridor alive to x1380 in 38464588882; spike-kill and checkpoint revival still separate | One representative hazard/respawn check if needed |
| Piggyback and interaction/talk | Levels 3–4 | SOURCE/MAP instructions present, no live proof (QA-only original Level1 does not exercise B) | Targeted real input proof (one of 3 or 4) |
| Checkpoint and restart | Level 5 (also 21–22, 25, 27, 30, 36) | SOURCE/MAP checkpoint objects and tutorial, no live respawn proof | One checkpoint→death→respawn example |
| Moving platform, triggered platform | Levels 1/13 | SOURCE/MAP; level 13 explicitly teaches landing-triggered movement | One moving and one triggered-platform observation |
| Collectible bottle/sugar/lives, persistence | Level 1 and Level 9 | SOURCE/MAP; level 9 explains collected bottle turns orange | One bottle+revisit or save/reload proof |
| Pause/resume and menu restart | Level 11 or any level | SOURCE/MAP Level 11 help prompt; separate Q5 workflows exist | One runtime demonstration or existing verified equivalent |
| Real level completion and unlock | Any representative naturally solved stage | Strict `levelFinished && levelOverMenu && both alive` classifier. No current natural Level2 win. New isolated QA Level1 movement/jump/switch/double-jump success DOES NOT change authentic progression status. | At least one real finish, Next Level transition, reopen/relaunch persistence |
| Factory chapter title, geometry, mechanic variety | Level 13 / sample 16–22 | SOURCE/MAP reviewed | Enter chapter normally; inspect, exercise at least one unique feature |
| Management chapter title, geometry, mechanic variety | Level 25 / sample 27–36 | SOURCE/MAP reviewed | Enter chapter normally; inspect, exercise at least one unique feature |
| Air dash | Level 32 | SOURCE/MAP explicit tutorial | One real airborne X/action response |
| Later-level breadth | Map definitions 1–36 sequentially scanned | SOURCE/MAP, representative mechanics recur | Representative load/render checks, not all levels cleared pixel-by-pixel |

## 2026-10-14 bounded Level 1 navigation investigation — STOP-LOSS

- **38487820204** (commit b5a0b6e8): genuine fresh Level 1 entry reached the Warehouse story cinematic, not gameplay. Nine chronological screenshots show multiple distinct authentic dialogue lines responding to ordinary X input. Failure was a QA cutoff before the cinematic finished, not a gameplay mechanic failure. Full screenshots resolved the false level-select classification.
- **38488276112** (commit 6d1b47ca): source-confirmed Y cinematic skip (PCCinematicState.as) was issued via adb shell input keyevent KEYCODE_Y. Sequential screenshots remained on the opening dialogue. This emulator injection method has not proved the Y control was received; no real gameplay-state snapshot was produced. Product verdict: INCONCLUSIVE, not RED. The cinematic itself loaded correctly.
- **Stop-loss triggered:** screen-navigation/input dispatch is the repeated failure, not a demonstrated game mechanics regression. Do not queue another UI pixel classifier or cutscene-input permutation merely to make CI green. Choose a different bounded evidence path for unproven mechanics, distinguishing isolated QA-only scene evidence from authentic unlock/persistence, or obtain actual Fold/manual user-input evidence. Never edit saves, grant synthetic unlocks, teleport, alter physics, or force completion to claim release progression.
- **Current status:** piggyback, triggered moving platform, checkpoint/respawn, collectible persistence, pause/restart, real finish→unlock, later chapter rendering remain unverified at this cutoff. Previous genuine Level2 mechanics evidence remains valid. No new product RED.

## 2026-10-14 ACTUAL isolated-Rev52-mechanics runtime result

- **Run38490845197 SUCCESS**, source-verified isolated original Level1 from exact canonical Rev52 candidate `0d5fd0bb63558ad6659ba31552deaede4745382b`. Game data/physics/source are unchanged except the QA-only menu entry and read-only PCPlayState observation in the test APK. Runner uses the **two genuine X intro inputs** required by `PCIntroState.as` to reach the QA-only menu hook; it neither edits save/unlocks, teleports player positions, nor forces completion.
- Six timestamped actual PlayState records and 8 rendered screenshots read end to end in evidence artifact **11862060943**: initial original Warehouse Level1, Andre x20→100.56 controlled real walk, held jump p1y499.11→449.66 with p1vy−225.92, V switch p1controlled true→false and p2controlled false→true, Liselot x20→73.76 with ordinary RIGHT. **Both alive, no finish.**
- Female second airborne C press produced **observed distinct renewed upward impulse**, p2vy **−44.2 before → −224.2 after** while x remained 73.76, p2y165.57→119.27: a real double-jump response, not merely two sent keycodes. Upgrade *only the isolated QA emulator double-jump mechanic* to OBSERVED.
- Exact evidence ZIP 449,447 bytes SHA256 `12ece39d5e243b30933f9bc9ca95fec81938017f99281c6e0ba8a2ebe62e7283` preserved in owning Drive ARTIFACTS ID `12EVHsl9dvQ3jdMkzWpcOPycG_Kx3bNkJ`. Cold-downloaded Drive copy hash equals originally fetched GitHub artifact; CRC PASS.
- All these mechanics are **ISOLATED QA-EMULATOR OBSERVED** on an exact Rev52 gameplay-source-derived APK, not exact unmodified release APK, natural title/menu navigation, genuine completion/unlock persistence, physical device, or Play certification. Those stay separate gates.

## New QA-only execution lane: authored direct-scene smoke

- **Reason:** UI/cinematic automation exhausted the stop-loss budget without testing mechanics. The owner explicitly prioritized representative mechanics over an elaborate perfect-playthrough robot.
- **Isolation:** `qa/gate2a-direct-scene-proof` is a separate branch derived from this matrix lane. Its only allowed gameplay-source deltas against pinned Rev52 `0d5fd0bb` are the already-read-only observer in `src/PCPlayState.as` and a visibly marked QA-only `src/PCMenuState.as` direct entry to the **unmodified authored Warehouse Level 1**. No gameplay physics, entities, hazards, saves, level XML, checkpoint logic or unlock state are modified. The branch is **PROHIBITED FROM SHIPPING**.
- **Run:** initial Windows-build + Android emulator pipeline [38489383433](https://github.com/masterramy/SuperLemonadeFactoryOUYA/actions/runs/38489383433). Source [`qa/mechanics_direct_scene.py`](https://github.com/masterramy/SuperLemonadeFactoryOUYA/blob/qa/gate2a-direct-scene-proof/qa/mechanics_direct_scene.py). Inspect actual CI conclusion and saved screenshots/state-trace before promoting any OBSERVED mechanic status; until then **RUNNING/UNPROVEN**.
- **Permitted inference:** if actual runtime evidence shows a character moving/jumping/switching as expected in the original map, only that specific mechanic may be called an *isolated QA-emulator OBSERVED* pass. A second airborne input alone is not proof of a second jump impulse. No identical release binary / physical device parity can be inferred.
- **Not permitted:** direct-scene entry must **never** stand in for natural UI selection, chapter unlocks, level completion, post-victory transitions, real save persistence, signing, or release qualification. These remain individually scoped gates, and must be tested by ordinary controls in unmodified shipping runtime.

## Active QA runs

- Original slow route runner `qa/rev52-observed-playthrough`: diagnostic source for prior successful mechanics; **not** a release readiness gate by itself. Repeated controller precision failures must not monopolize work.
- New separate branch `qa/gate2a-mechanics-coverage`: explicit matrix + bounded real-input smoke. Runs **38480810765/38481259245/38481655023** exposed UI/cinematic classifier limitations before any mechanic assertions; marked QA automation inconclusive, **not a product RED**. Stop retrying this harness unless there is genuinely new UI evidence.
- Continue with new *mechanic classes* and normal progression verification, then stop once confidence is supported. Report any genuinely broken mechanic with a reproducible sequence and rendered evidence.

## Acceptance boundary

Do not claim "whole game verified" solely from source scans or one tutorial. Conversely, do not require a flawless 36-level bot when the owner's objective is a solid breadth audit. Distinguish **mechanics functionality**, **level loading/rendering**, **progression/persistence**, and **full campaign manual completion** as separate assertions.
