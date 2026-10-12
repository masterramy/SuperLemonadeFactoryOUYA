# Gate 2A games continuation checkpoint — 2026-10-11 23:xx PT

This is a QA-branch fallback continuity pointer only. Canonical Drive Gate2A authority outranks this file and must be reconciled, not overwritten.

Protocol epoch probed: Workspace Protocol v1.7 rev30, schema 2.1, chief notice CHIEF-2026-10-07-047.

Owner intent: finish genuine ordinary-input full-game Super Limeade Factory playthrough, audit and fix LIMEADE font/spacing/style to match SUPER and FACTORY, use Superpowers systematic debugging, TDD and verified screenshots. Do not publish or upload to Play.

Shipping: Rev50 is Master-promoted (354e354809d240811cd2bc50aea3b4017ca7b3e4); Rev51 is accepted corresponding source for Rev50 only. Rev52 remains unpromoted title candidate and must have Master adjudication and corresponding source before release.

Title candidate branch gate2a-rev52-title-playthrough-repair:
- original matched title font/pixel ink from Rev52, confirmed in earlier QA branch qa/rev52-title-composition at 9e76e236f68431e10afc667d05379889ca85ad0f, run 38127540349 SUCCESS, 1920x1080 and 2560x1440.
- transparent TAP TO START background applied to real Rev52 candidate in src/MobileControls.as, 4a64d6d.
- actual candidate build run 38212289872 built but screenshot geometry failed because Android Pixel Launcher ANR overlay covered title.
- another real title defect caught: old 'Press O to start' text in src/PCIntroState.as contradicted TAP TO START. RED source test then legacy text/field creation removed in commit 3c4d155.
- candidate title CI harness updated to recognize/dismiss only Android system UI dialogs; regex fixed in latest candidate head 0d5fd0bb63558ad6659ba31552deaede4745382b. Exact rendered test run 38213530317 was IN PROGRESS at this checkpoint; inspect result/artifact before claiming PASS. Static title audit already PASS.

Gameplay QA only: qa/rev52-observed-playthrough. Read-only observer + ordinary ADB input. No save edits, teleport, forced completion, physics changes. Guard controller already contains a one-time bounded grounded retry after observed Andre at x210,y479; TDD unit tests green, but runtime was blocked upstream in launch stage.
- Genuine observed previous run 38127257088: Liselot alive near exit x1329, Andre alive x210 before guard. NO Level2 victory.
- Root cause in later run 38213127671: Level2 ACTUALLY launched; screenshot classifier mistakenly called game 'level_select' due purple UI, causing redundant taps. Contact sheet from artifact 11730156978 showed six tan bottom controls in gameplay.
- TDD RED test in qa/test_screen_navigation.py at 49aeaaa and improved qa/screen_navigation.py to detect six tan HUD positions before purple level_select logic in qa head d4a3eb0a930a328145baf57d1059379a1d84b674. Run 38213821089 was IN PROGRESS; unit tests PASS. Inspect actual trace/screens/CI outcome next, do not claim Level2 finish from test pass.

Preserve strict genuine completion guard: levelFinished AND levelOverMenu AND neither character dead. If pass, repeat ordinary inputs on UNINSTRUMENTED exact Rev52 candidate before shipping proof. Then extend natural playthrough to later levels, no shortcut via save mutation.

The canonical Drive WORKER_HANDOFF was fetched and whole-read but an attempted transport update was blocked by connector safety, so this GitHub checkpoint is a fallback and NOT proof canonical Drive got updated. There may be an orphan temp Google Doc __TMP_GATE2A_HANDOFF_OCT11_CONTINUATION ID 19VXkX7HCEKTMNK7nC3VUWrTvus26w3Oj91gt5Qc6yb8; deletion was also blocked. Recheck before cleanup.
