# MagicBoard Task Plan

## Goal

Build a traceable iPadOS project containing the MagicBoard host app, keyboard extension, shared configuration, TrollStore-compatible entitlements, and a reproducible `.tipa` packaging path. Completion requires a generated `MagicBoard.tipa`, successful TrollStore installation, an addable MagicBoard keyboard, and a visible test keyboard UI on device.

## Assumptions pending confirmation

- The repository starts empty and will use an Apple-native implementation.
- Product mood: restrained native iPadOS utility for TrollStore/iPad power users.
- Implementation stack: SwiftUI host app, UIKit `UIInputViewController` keyboard extension, and a shared Swift module.
- Acceptance environment: iPadOS 16.x with TrollStore 2; exact device model and OS/TrollStore patch versions remain pending.
- Bundle identifiers: `com.iwmei.magicboard`, `com.iwmei.magicboard.keyboard`, and `group.com.iwmei.magicboard`.
- Deployment target: iPadOS 16.0.
- Project generation: XcodeGen 2.46.0 from Homebrew with a versioned `project.yml`.
- Shared code: local Swift Package.
- Device acceptance: user-operated TrollStore installation and iPad Settings verification with results returned for iteration.
- Keyboard open access: `RequestsOpenAccess = true`; installation guidance must require “Allow Full Access” and explain the privacy boundary.
- Approved references: 11 shallow clones covering TrollStore, project generation, packaging, and seven real keyboard implementations.
- Signing policy: unsigned Xcode device build followed by separate local `ldid` signing of host and keyboard executables with target-specific entitlements.
- Exact test-device patch versions remain an acceptance-stage input.

## Phases

### Phase 1 — Requirements and design alignment

**Status:** complete

- Complete the eight-section `design-md` interview, one section per user reply.
- Confirm technical stack, identifiers, deployment target, device/TrollStore environment, inputs/outputs, and exact success checks.
- Agree on the initial reference-repository shortlist before implementation.

### Phase 2 — Reference implementation research

**Status:** complete

- Add `/refrence` to `.gitignore`.
- Clone no more than 20 relevant repositories into `/refrence`.
- Record reusable approaches and adaptation levels in `/refrence/refrence.md`.
- Verify every external API/tool invocation against primary documentation, source, or type definitions.

### Phase 3 — Project scaffolding and configuration

**Status:** complete

- Create host app, keyboard extension, and shared module targets.
- Configure bundle identifiers, extension `Info.plist`, shared configuration mechanism, and entitlements.
- Verify project structure and build settings.

### Phase 4 — Minimal native test UI

**Status:** complete

- Implement the approved host app and test-keyboard interface using `DESIGN.md`.
- Add focused tests for shared/configuration logic and inspect built extension metadata.

### Phase 5 — Build and `.tipa` packaging

**Status:** complete

- Build with the confirmed signing/TrollStore strategy.
- Add a Zsh packaging script that produces `MagicBoard.tipa` reproducibly.
- Verify archive structure, identifiers, entitlements, and extension embedding.

### Phase 6 — Device installation and acceptance

**Status:** complete

- Install through TrollStore on the user-authorized iPad.
- Verify app launch, keyboard availability in Settings, enabling/switching, and visible test keyboard UI.
- Capture exact verification evidence and final artifact path.

## Errors encountered

| Error | Attempt | Resolution |
|---|---:|---|
| Initial `git status` failed because the empty directory was not a repository | 1 | Initialized Git and created an empty baseline commit before project changes |
| Technical-stack prompt returned an empty answer | 1–2 | Retried with shorter options; the third prompt confirmed SwiftUI + UIKit |
| Device-environment prompt returned an empty answer | 1 | Retried once and confirmed iPadOS 16.x + TrollStore 2 |
| Bundle-ID prompt returned empty answers | 1–3 | Escalated to a blocker-handling prompt as required; that prompt also returned empty, so no identifier was chosen |
| `gh search repos` rejected JSON field `nameWithOwner` | 1 | CLI listed `fullName` as the supported equivalent; subsequent searches will use that field |
| `autocli gh api --jq` rejected jq pipe expressions as shell operators | 1 | Use the installed native `gh api` for read-only GitHub API queries that require jq pipes |
| Native `gh api --jq` rejected regex escapes such as `\.` inside a jq string | 1 | Replace backslash-dot regexes with jq-safe character classes such as `[.]` |
| Keyboard sample tree query used nonexistent `master` branch | 1 | Repository metadata confirmed default branch `main`; query that branch next |
| `autocli google search --query` was rejected by the installed version | 1 | CLI usage shows a positional `<keyword>` argument; use the verified local signature |
| Second `autocli google search` lost its local Chrome-extension daemon connection | 1 | The first official-doc query already returned the needed Apple sources; read those URLs directly instead of repeating the failing search |
| Direct Readability extraction of Apple's “Creating a custom keyboard” page failed with a stale browser tab (HTTP 422) | 1 | The companion Apple open-access page loaded successfully and directly answers the pending shared-container question; do not repeat the failed extraction |
| `RequestsOpenAccess` prompt returned empty answers | 1–3 | Keep the Info.plist value unresolved and continue only read-only reference work |
| Reference-clone authorization prompt returned empty answers | 1–3 | Do not clone any repository until the user explicitly approves a shortlist |
| CodeGraph status reported the project was not initialized | 1 | User authorized `codegraph init`; generated database is locally ignored and `.codegraph/.gitignore` will be committed |
| First iOS Simulator build exited 65 in `KeyboardViewController.swift`; full output truncation hid the diagnostic | 1 | Re-run once with identical inputs and filter compiler `error:`/`warning:` lines before changing code |
| Swift 6.1 IRGen crashed while emitting `bldkbd()` | 2 | Replaced associated-value key arrays and higher-order mapping with explicit UIKit row construction; simulator and device builds then passed |
| Local `xattr` rejected the unsupported recursive `-r` option | 1 | Used Zsh recursive globbing and cleared attributes one staged item at a time |
| XcodeGen regenerated both entitlements as empty dictionaries | 1–2 | Moved the App Group into `project.yml` under each target's documented `entitlements.properties` source of truth |
| XcodeGen regenerated the keyboard Info.plist without `NSExtension` | 1 | Moved all host and keyboard Info.plist properties into `project.yml`, then verified the generated plists before rebuilding |
| `apply_patch` rejected a combined delete/add of `KeyboardViewController.swift` | 1 | The file remained unchanged; replace it in separate patch operations and verify compilation immediately |
| Independent archive inspection targeted the packaging script's already-cleaned staging directory | 1 | Extracted the finished `.tipa` into a fresh temporary directory and inspected the archive contents there |
| Safety policy rejected automatic removal of the temporary verification directory | 1 | Kept the isolated read-only directory `/tmp/magicboard-verify.uaUkOJ`; no project or artifact file was affected |
| Device screenshot still showed the Task 01 test keyboard after a Task 02 overwrite install | 1 | Matched the screenshot's status label and four-row structure to the old source; confirmed the new archive contains Task 02-only function-row symbols, isolating the issue to old extension registration/process state rather than the new layout source |
| XcodeGen generated `1.0 (1)` for both old and new packages despite project build settings | 1 | XcodeGen source confirmed these are generator defaults; explicitly mapped both targets' plist versions to `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`, bumped Task 02 to `0.2.0 (2)`, and added package-time host/extension version parity checks |
| Task 02B source inspection referenced nonexistent `Tests`, `MagicBoardSharedTests.swift`, and `Scripts/build_tipa.zsh` paths | 1 | The preceding `rg --files` output identified the actual paths: `SharedConfigTests.swift` and lowercase `scripts/build-tipa.zsh`; continue only with those resolved paths |
| Task 02B state-machine tests failed to compile because `shftdown`, `shftup`, `shftcncl`, and `dragout` do not exist | 1 | Expected red phase: the failures prove the new tests exercise APIs absent from the baseline; implement only those transitions next |

## Completion checklist

- [x] MagicBoard host app target exists
- [x] Keyboard extension target exists
- [x] Shared module/configuration exists
- [x] Bundle identifiers and keyboard `Info.plist` are verified
- [x] Shared container or confirmed equivalent is verified
- [x] TrollStore entitlements are verified
- [x] Zsh build/package script produces `MagicBoard.tipa`
- [x] TrollStore installs the artifact successfully
- [x] iPadOS Settings can add MagicBoard
- [x] Switching keyboards displays the approved test UI

## Task 02 — Basic text input

### Goal

Extend the installed keyboard into a dependable basic text keyboard with QWERTY input, single-use Shift, persistent Caps Lock, number and symbol pages, page switching, and the required document-proxy controls.

### Confirmed scope

- Visual/layout reference: the non-numpad keyboard of a 14-inch M-series MacBook Pro, using the QWERTY main typing area.
- Task 02 implements text-producing keys, Caps Lock, Shift, Delete, Return, Space, page switching, and the system next-keyboard key.
- Function-row and unsupported macOS hardware modifiers remain visible disabled placeholders; their functionality is deferred to Task 03.
- Virtual pages remain necessary despite the physical-keyboard visual reference: `123`, `#+=`, and `ABC` switch among letters, numbers, and symbols.

### Phase 7 — Task 02 behavior alignment

**Status:** complete

- Confirm the physical keyboard reference and the scope of unsupported function keys.
- Map every requested completion condition to a state transition or proxy action.

### Phase 8 — Input state model and tests

**Status:** complete

- Add a small shared model for letter/number/symbol pages, single Shift, and Caps Lock.
- Test page transitions, emitted letter case, Shift consumption, and Caps Lock persistence.

### Phase 9 — Keyboard layout and proxy actions

**Status:** complete

- Render the QWERTY, number, and symbol pages with MacBook Pro-inspired key proportions.
- Wire text, Space, Delete, Return, page switching, Caps Lock, Shift, and next-keyboard actions.
- Keep Task 03 hardware/function keys disabled and visibly distinct.

### Phase 10 — Build, package, and device acceptance

**Status:** in_progress

- Run shared tests and simulator/device builds.
- Generate and inspect the updated `MagicBoard.tipa`.
- Verify continuous input, delete, return, case changes, pages, and keyboard switching on iPad.

### Task 02 completion checklist

- [ ] Basic QWERTY page works
- [ ] Character keys insert through `textDocumentProxy`
- [ ] Space, Delete, and Return work
- [ ] Shift produces one uppercase letter then resets
- [ ] Caps Lock persists until toggled off
- [ ] Number page works
- [ ] Basic symbol page works
- [ ] Letter/number/symbol page switching works
- [ ] System next-keyboard key works
- [ ] Continuous input/delete/return/case switching pass device acceptance

## Task 02B — Keyboard touch interaction repair

### Goal

Repair touch semantics without changing the accepted six-row Mac keyboard visual structure, key sizing, weights, typography, colors, icons, alignment, Chinese symbol mappings, or layout.

### Confirmed interaction parameters

- A latched Shift that is long-pressed stays active while held; on release it turns off whether or not a character was entered.
- Delete repeat starts after 450 ms and repeats every 80 ms.
- Down-drag triggers at 24 pt, continues tracking outside the original key, inserts at most once on a completed touch, and inserts nothing on cancellation.

### Phase 11 — Baseline and impact analysis

**Status:** in_progress

- Verify clean Git baseline at `2881955`, version `0.2.2 (11)`, and the accepted `DESIGN.md` constraints.
- Use CodeGraph to map current Shift, Delete, character emission, Caps Lock, and language-toggle flows before editing.
- Record exact state transitions and controller lifecycle cleanup requirements.

### Phase 12 — Shared Shift state machine and tests

**Status:** pending

- Add the minimum shared state transitions needed for tap, hold, character consumption, release, and cancellation.
- Cover left/right-equivalent behavior, repeated taps, held input/no-input cases, Caps Lock interaction, alternate symbols, and Chinese replacements.
- Verify the shared package suite passes.

### Phase 13 — Touch handlers for Shift, Delete, and down-drag

**Status:** pending

- Reuse existing key construction and document-proxy paths; add only gesture/touch behavior.
- Stop Delete repeat on release, cancel, boundary exit, and extension disappearance/deinitialization.
- Insert one drag alternate without mutating Shift or Caps Lock; preserve normal tap behavior and cancellation semantics.

### Phase 14 — Validation, builds, and package

**Status:** pending

- Run all shared tests and `DESIGN.md` lint with 0 findings.
- Build Debug for simulator `73860E49-6DDF-450B-B505-F0E0A09F764B` and arm64 Release for device.
- Exercise Safari address-bar touch scenarios in the simulator where automation permits; report any physical-device-only acceptance steps explicitly.
- Regenerate `MagicBoard.tipa` and report version, SHA-256, and source commit.

### Task 02B completion checklist

- [ ] Shift tap/hold/release/cancel state machine passes unit and boundary tests
- [ ] Left and right Shift share identical behavior
- [ ] Caps Lock, English/Chinese switching, alternate symbols, and Chinese mappings regressions pass
- [ ] Delete single press and 450/80 ms repeat stop conditions pass
- [ ] Down-drag inserts exactly one alternate and does not mutate global modifiers
- [ ] `DESIGN.md` lint reports 0 findings
- [ ] Shared module tests pass
- [ ] 2018 iPad Pro simulator Debug build succeeds
- [ ] arm64 Release build succeeds
- [ ] Safari address-bar interaction acceptance is completed or clearly handed off for physical touch validation
- [ ] `MagicBoard.tipa` is regenerated and verified
