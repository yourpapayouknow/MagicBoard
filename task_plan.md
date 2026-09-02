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
| Task 02B simulator Debug build rejected direct UIKit access from `Timer` Sendable closures | 1 | Swift 6 correctly identified MainActor isolation; hop timer callbacks explicitly to `@MainActor` and recheck the owned timer before deleting |
| Task 02B simulator Debug build rejected `Timer?` access from nonisolated controller `deinit` | 2 | The timer is confined to the main RunLoop; mark only this stored property `nonisolated(unsafe)` so deinit can invalidate it without weakening other UIKit isolation |
| Final entitlement inspection used a dotted `plutil -extract` key path that split the entitlement key incorrectly | 1 | The archive and package-time PlistBuddy checks already passed; read the exported entitlement plists with `/usr/libexec/PlistBuddy` for the independent verification |
| Down-drag visual Debug build inferred local `27 / 22` reset scale as `Int` | 1 | Give the local scale an explicit `CGFloat` type; the interpolation expression already inferred correctly from its `CGFloat` progress operand |

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

**Status:** complete

- Verify clean Git baseline at `2881955`, version `0.2.2 (11)`, and the accepted `DESIGN.md` constraints.
- Use CodeGraph to map current Shift, Delete, character emission, Caps Lock, and language-toggle flows before editing.
- Record exact state transitions and controller lifecycle cleanup requirements.

### Phase 12 — Shared Shift state machine and tests

**Status:** complete

- Add the minimum shared state transitions needed for tap, hold, character consumption, release, and cancellation.
- Cover left/right-equivalent behavior, repeated taps, held input/no-input cases, Caps Lock interaction, alternate symbols, and Chinese replacements.
- Verify the shared package suite passes.

### Phase 13 — Touch handlers for Shift, Delete, and down-drag

**Status:** complete

- Reuse existing key construction and document-proxy paths; add only gesture/touch behavior.
- Stop Delete repeat on release, cancel, boundary exit, and extension disappearance/deinitialization.
- Insert one drag alternate without mutating Shift or Caps Lock; preserve normal tap behavior and cancellation semantics.

### Phase 14 — Validation, builds, and package

**Status:** complete

- Run all shared tests and `DESIGN.md` lint with 0 findings.
- Build Debug for simulator `73860E49-6DDF-450B-B505-F0E0A09F764B` and arm64 Release for device.
- Exercise Safari address-bar touch scenarios in the simulator where automation permits; report any physical-device-only acceptance steps explicitly.
- Regenerate `MagicBoard.tipa` and report version, SHA-256, and source commit.

### Task 02B completion checklist

- [x] Shift tap/hold/release/cancel state machine passes unit and boundary tests
- [x] Left and right Shift share identical behavior
- [x] Caps Lock, English/Chinese switching, alternate symbols, and Chinese mappings regressions pass
- [x] Delete single press and 450/80 ms repeat stop conditions pass
- [x] Down-drag inserts exactly one alternate and does not mutate global modifiers
- [x] `DESIGN.md` lint reports 0 findings
- [x] Shared module tests pass
- [x] 2018 iPad Pro simulator Debug build succeeds
- [x] arm64 Release build succeeds
- [x] Safari address-bar interaction acceptance is completed or clearly handed off for physical touch validation
- [x] `MagicBoard.tipa` is regenerated and verified

### Phase 15 — Down-drag visual keyframes

**Status:** complete

- Keep the accepted static keycap title and all layout/style values byte-identical outside an active drag.
- During an unshifted dual-symbol drag, fade and scale the lower base while moving the upper alternate to center.
- During a lowercase letter drag, temporarily show uppercase above the current letter and apply the same transition.
- Drive progress continuously from 0–24 pt; successful and cancelled gestures restore the static title in 120 ms.
- Preserve the existing final-displacement commit rule, one-character limit, language mappings, and Shift/Caps state.

### Phase 16 — Visual validation and repackaging

**Status:** complete

- Add focused checks for visual interpolation endpoints where practical.
- Re-run `DESIGN.md` lint, all shared tests, simulator Debug, and arm64 Release.
- Re-inspect the fixed layout/style baseline outside the new transient overlay.
- Regenerate `MagicBoard.tipa` and report the new SHA-256 and implementation commit.

### Down-drag visual completion checklist

- [x] Active drag interpolates the two legend layers over 0–24 pt
- [x] Success and cancellation restore the accepted static legend in 120 ms
- [x] Static key layout, style, mappings, and six-row structure remain unchanged
- [x] `DESIGN.md` lint reports 0 findings
- [x] Shared module tests pass (20/20)
- [x] 2018 iPad Pro simulator Debug build succeeds
- [x] arm64 Release host and keyboard extension build succeeds
- [x] `MagicBoard.tipa` is regenerated and structurally verified
- [x] Target-device motion appearance matches the supplied three reference frames

## Task 03 — Magic Keyboard layout

### Confirmed scope

- Task 03 is the already-completed layout work contained in the commits currently described as Task 02 layout refinements.
- Esc, Ctrl, Option, Command, and the four arrow keys are present as visual keys/placeholders; their HID behavior is intentionally deferred to Task 04.
- Rewording historical commit messages is separate from Task 04 implementation because it rewrites every descendant commit ID.

## Task 04 — TrollStore HID special-key path

### Goal

Add one native TrollStore HID event path for Esc and the four arrow keys while preserving the existing `textDocumentProxy` path for text-producing keys and keeping the accepted keyboard layout unchanged.

### Phase 17 — TrollVNC source and entitlement research

**Status:** complete

- Locate the authoritative TrollVNC HID keyboard-event implementation and record the exact client creation, event construction, usage-page/usage mappings, sender identity, and dispatch sequence.
- Verify the required private framework symbols and TrollStore entitlements against source, headers, and the current project target/package flow.
- Confirm that no Dopamine, Bootstrap, Substrate, compatibility layer, or runtime hook is part of the selected path.

### Phase 18 — HIDBridge model and tests

**Status:** complete

- Add one independent `HIDBridge` module with a minimal supported-key model for Esc and four arrows.
- Cover HID usage mappings and paired key-down/key-up dispatch behavior with focused tests where the private API boundary permits deterministic local verification.
- Keep private API declarations isolated from the keyboard controller.

### Phase 19 — Keyboard routing and TrollStore entitlements

**Status:** complete

- Route the existing Esc and arrow layout keys through `HIDBridge` without changing their accepted position, size, or touch area.
- Configure the minimum verified host/extension entitlements in `project.yml` and the checked-in entitlement plists.
- Extend packaging checks so the final keyboard executable demonstrably retains every required HID entitlement.

### Phase 20 — Build, package, and device acceptance

**Status:** complete

- Run shared tests, simulator compilation where supported, and generic arm64 Release packaging.
- Inspect the final `.tipa`, binary architectures, Info.plists, and exported entitlements.
- Verify Esc and all four arrows as physical-keyboard events in at least two foreground apps on the target TrollStore device.

### Task 04 completion checklist

- [x] TrollVNC HID keyboard-event source and adaptation notes are recorded
- [x] Independent `HIDBridge` exists
- [x] Required TrollStore entitlements are configured and package-verified
- [x] `IOHIDEventSystemClient` creation succeeds on the target device
- [x] Esc sends paired HID key down/up events
- [x] Left, Right, Up, and Down send paired HID key down/up events
- [x] Two foreground apps accept all four directions as physical-keyboard navigation
- [x] An app with hardware Esc support recognizes Esc
- [x] The HID path uses no Dopamine, Bootstrap, Substrate, compatibility layer, or runtime hook

## Task 05 — Spacebar trackpad cursor mode

### Goal

Preserve ordinary Space input while adding a native-keyboard-style long-press drag mode that moves the insertion cursor freely and exits cleanly without inserting a space.

### Phase 21 — Interaction and implementation alignment

**Status:** complete

- Inspect the current Space touch path and reusable gesture/HID implementations.
- Verify UIKit gesture cancellation behavior and the available cursor-position APIs from primary declarations or source.
- Confirm the long-press threshold, movement model, and active visual state before editing code.

### Confirmed interaction parameters

- A short Space tap inserts exactly one space through the existing document-proxy path.
- Holding Space for 0.45 seconds enters trackpad mode and cancels that touch's Space insertion.
- Each accumulated 12-point drag step emits one paired HID arrow event; the foreground app resolves real character and visual-line navigation.
- The dominant axis wins for diagonal movement, residual distance is retained, and changing direction discards stale residual movement on that axis.
- Active mode transforms the entire keyboard region into a native-style trackpad surface; release or cancellation restores the complete accepted keyboard appearance.
- The active surface is one uninterrupted dynamic light-gray overlay covering the full key grid; all keycap labels, icons, fills, and boundaries disappear together, while Reduce Motion disables the short transition.

### Phase 22 — Cursor movement model and focused tests

**Status:** complete

- Add only the minimum testable state needed to distinguish a short Space tap from an active/cancelled trackpad gesture.
- Cover activation, movement thresholds, residual movement, direction changes, release, cancellation, and ordinary Space regression.

### Phase 23 — Space gesture wiring and feedback

**Status:** complete

- Reuse the existing Space key and accepted layout without changing its size or position.
- Route active drag movement through the confirmed cursor mechanism and suppress Space insertion after recognition.
- Hide the full keyboard's keycap content and boundaries while trackpad mode is active, then restore the normal appearance and state on release, cancellation, view disappearance, and teardown.

### Phase 24 — Build, package, and device acceptance

**Status:** in_progress

- Run focused/shared tests, design lint, simulator Debug, and generic arm64 Release packaging.
- Verify the final archive, entitlements, versions, and artifact hash.
- On the target iPad, verify short Space taps, long-press activation, four-direction cursor movement, cancellation, and regression behavior in at least two text editors.

### Task 05 completion checklist

- [ ] Short-tapping Space inserts exactly one space
- [ ] Long-pressing Space enters cursor mode without inserting a space
- [x] Dragging is wired to the confirmed directions and sensitivity
- [x] Reversing direction does not accumulate stale movement
- [x] Release and cancellation always restore the normal Space state in the implementation lifecycle
- [x] Active mode presents one full-keyboard native-style trackpad surface and restores every key afterward
- [ ] Existing text, Shift, Delete, down-drag, Esc, and arrow behavior remains intact
- [x] `DESIGN.md` lint and all automated builds/tests pass
- [ ] A regenerated `.tipa` passes target-device acceptance in two text editors

## Function 05 — Ctrl / Option / Command HID modifiers

### Goal

Enable the existing Control, left/right Option, and left/right Command keycaps as real held HID modifiers. While any of these modifiers is active, letter keys must emit paired HID keyboard events and must never insert through `textDocumentProxy`; the foreground app remains the sole shortcut interpreter.

### Phase 25 — State model and HID usage verification

**Status:** complete

- Verify modifier and A–Z USB HID usages against the installed Apple IOKit usage-table declarations.
- Add one shared `ModifierState` that distinguishes all five physical modifier keycaps and exposes only active-state transitions/querying.
- Add focused tests for initial state, independent press/release, duplicate transitions, simultaneous left/right modifiers, and reset.

**Expected red test:** the first shared-suite run fails only because `ModifierState` and `ModifierKey` are not implemented yet. Resolution is the minimum shared state model described above.

### Phase 26 — Keyboard routing and cleanup

**Status:** complete

- Extend the existing `HIDBridge` key enum only; do not create another event client or shortcut-command layer.
- Reuse touch down/up/cancel lifecycle for the five modifier keycaps and preserve independent left/right HID usages.
- Route A–Z through paired HID events only while a modifier is active; keep unmodified text on the existing document-proxy path.
- Release and reset every active modifier on cancellation, rebuild, disappearance, and teardown.

### Phase 27 — Automated validation and package

**Status:** complete

- Run the expected red shared tests, implement the minimum state model, and rerun the full suite.
- Build the simulator Debug target, lint `DESIGN.md`, and regenerate/inspect the arm64 TrollStore package.
- Confirm the diff contains no hard-coded Command+A/C/V/Z behavior and no foreground-app business logic.

**Errors recorded:** the first simulator build found that single-letter C enum members import as `.A...Z`, not `.a...z`; direct Swift type checking confirmed the importer names and the corrected build passed. A first diagnostic command encoded newlines literally and was replaced with a semicolon-delimited compiler input. The first post-write CodeGraph status retry returned `Transport closed`; final validation will retry once after packaging.

### Phase 28 — Foreground-app acceptance

**Status:** complete

- Verify Command+A, Command+C, Command+V, Command+Z, and one app-specific Command shortcut on the target device.
- Verify at least one Control combination and one Option combination are recognized by foreground apps.
- Confirm active modifiers suppress proxy text insertion and all shortcut outcomes are produced by the foreground app.

### Function 05 completion checklist

- [x] Unified `ModifierState` covers Control and both physical Option/Command keys
- [x] Control, Option, and Command send real HID down/up events with cancellation cleanup
- [x] Modifier + A–Z sends paired HID keyboard events
- [x] Modifier-active letters never call `textDocumentProxy.insertText`
- [x] Command+A/C/V/Z work in a foreground app
- [x] At least one foreground-app-specific Command shortcut works
- [x] At least one Control and one Option combination are recognized by foreground apps
- [x] No shortcut behavior is hard-coded inside MagicBoard
- [x] Shared tests, design lint, simulator build, and arm64 package checks pass

## Function 05 bugfix — held Shift with HID keys

### Goal

Make both physical Shift keycaps participate in the real HID lifecycle so holding Shift while pressing or repeating arrow keys continuously selects text in the foreground app, without changing existing proxy-generated character behavior or leaving Shift latched/stuck after a chord.

### Phase 29 — Root cause and state-machine tests

**Status:** complete

- Preserve the accepted one-shot Shift, Caps Lock, held character, drag alternate, and cancellation semantics.
- Add physical left/right Shift identity to `InputState` and focused red tests for held HID use, repeated use, independent left/right release, cancellation, and final latch behavior.
- Verify Left/Right Shift USB HID usages against the installed Apple IOKit usage table.

**Expected red test:** the first shared-suite run failed only because the new `ShiftKey`, `shiftHeld`, and `shftuse` APIs did not exist. After the minimum state-machine extension, all 34 tests passed.

### Phase 30 — Shift HID lifecycle wiring

**Status:** complete

- Map the existing left and right Shift keycaps to HID usages `0xE1` and `0xE5` without changing layout or styling.
- Send Shift down/up on touch down/up/outside/cancel and mark the shared state machine used when another HID key begins.
- Preserve proxy text output while Shift alone is held; allow Shift to combine naturally with the existing Command/Control/Option HID path.
- Release all Shift HID state on rebuild, disappearance, and teardown through the existing `releaseAll` cleanup.

### Phase 31 — Regression validation and package

**Status:** complete

- Run the full shared suite, `DESIGN.md` lint, simulator Debug, generic arm64 Release packaging, and independent archive checks.
- Verify no changes to accepted key geometry, proxy behavior, modifier shortcut routing, or entitlements.
- Regenerate the TIPA and hand off held-Shift arrow selection plus stuck-key cancellation checks for target-iPad acceptance.

### Phase 32 — Target-iPad acceptance

**Status:** pending

- Install `0.6.1 (15)` and verify either Shift key plus repeated left/right/up/down arrows continuously extends or shrinks the foreground app selection.
- Verify releasing Shift stops selection extension, and cancellation, keyboard dismissal, rebuild, and app switching leave no stuck Shift state.
- Recheck one-shot Shift, held Shift character entry, Caps Lock, Command/Control/Option chords, standalone arrows, and Space trackpad behavior.

### Held-Shift bugfix completion checklist

- [x] Left and right Shift emit their own HID down/up usages
- [ ] Holding either Shift allows repeated arrow selection
- [x] Releasing one of two held Shift keys leaves the other active
- [x] Using an HID chord prevents an extra one-shot Shift latch on release
- [x] Touch cancellation, rebuild, disappearance, and teardown cannot leave Shift stuck
- [ ] Existing Shift/Caps/proxy text, Command/Control/Option, Esc/arrows, and trackpad behavior regressions pass
- [x] Tests, lint, simulator Debug, arm64 Release, and TIPA checks pass

## Task 06 — Sticky Modifier and resilient modifier cleanup

> **Superseded interaction:** Phase 40 removes Ctrl/Option/Command tap-to-Sticky after iPadOS system-overlay and accessibility conflicts were confirmed. Physical multi-touch holding and all resilient cleanup requirements remain current.

### Goal

Extend the accepted Ctrl/Option/Command HID path with two complementary interactions: physical multi-touch holding and one-shot Sticky Modifier taps. A Sticky modifier stays active until the next successfully completed non-modifier HID key, while every focus, input-mode, lifecycle, rebuild, and cancellation exit releases HID state and visual selection together.

### Confirmed implementation boundaries

- A clean tap on an inactive Ctrl/Option/Command key enables one-shot Sticky state; a second clean tap on the same Sticky key disables it.
- Tapping additional modifier keys combines them without consuming existing Sticky modifiers.
- Pressing another effective HID key while a modifier finger remains down uses physical-hold behavior and does not latch that held modifier after release.
- Sticky modifiers are consumed only after a non-modifier HID event completes successfully; cancelled gestures and failed HID dispatch do not consume them.
- Internal language changes, the system next-keyboard control, keyboard dismissal/rebuild, view disappearance, app resignation/backgrounding, and touch cancellation all converge on one idempotent HID reset path.
- Active held and Sticky modifiers keep the existing primary-cyan selected appearance; accessibility value distinguishes “已按下” from “已锁定”. No layout or design-token change is required.

### Phase 33 — Modifier state-machine tests

**Status:** complete

- Extend the existing `ModifierState` rather than add a second state owner.
- Add focused tests for tap-to-Sticky, tap-again unlock, multi-Sticky combinations, physical hold use, consume-after-success, independent left/right sources, cancellation restoration, and full reset.
- Run the shared suite first with expected failures for the new transition API, then implement the minimum model and rerun it.

**Expected red test:** the first run failed only on the intentionally missing `tap`, `cancel`, `use`, `consume`, and `isSticky` APIs. The minimum held/Sticky/used model then passed all 40 shared tests.

### Phase 34 — Controller routing and lifecycle cleanup

**Status:** complete

- Split modifier touch completion from cancellation so only `.touchUpInside` can toggle Sticky state.
- Consume Sticky state after successful text, Space, Return, Delete, Esc, arrow, and drag-generated HID completion while preserving held modifiers.
- Refresh all modifier keycaps and accessibility state from the shared model after every transition.
- Release all HID and local modifier/Shift state on internal/system input-mode switches, keyboard dismissal/rebuild, view disappearance, app resignation/backgrounding, and abnormal touch cancellation.

**Errors recorded:** the first simulator compile showed that the extension notification constants were already notification-name values; removing an extra wrapper exposed the Swift 3 renamed-member diagnostics. Using the compiler-declared `.NSExtensionHostWillResignActive` and `.NSExtensionHostDidEnterBackground` names resolved both errors, and the next full build passed.

### Phase 35 — Automated validation and package

**Status:** complete

- Run the complete shared suite, `DESIGN.md` lint, prohibited-shell scan, XcodeGen regeneration, simulator Debug build, generic arm64 Release package, and archive inspection.
- Verify the diff changes no key geometry, shortcut interpretation, entitlement scope, or independent HID event client.
- Bump host/extension together for the Task 06 package and report version, SHA-256, and source commit.

### Phase 36 — Target-iPad acceptance

**Status:** pending

- Verify held Ctrl/Option/Command multi-touch chords in foreground apps and confirm a clean tap immediately releases each modifier.
- Verify touch cancellation, keyboard dismissal, input-method switching, and foreground/background transitions never leave a modifier stuck.
- Recheck held Shift, one-shot Shift/Caps, Esc/arrows, Space trackpad, ordinary typing, and Delete behavior.

### Task 06 completion checklist

- [x] Ctrl, Option, and Command support physical multi-touch holding
- ~~Ctrl, Option, and Command support one-shot Sticky taps~~ — superseded; all modifier taps now release immediately
- ~~Sticky modifiers combine and a second tap unlocks the same modifier~~ — superseded by physical-hold-only policy
- ~~The next successfully completed effective HID key consumes Sticky state~~ — no Sticky state remains to consume
- [x] Active modifiers have clear selected styling and accessible state text
- [x] Focus loss, input-mode switching, rebuild, dismissal, app lifecycle changes, and touch cancellation release all HID modifiers
- [ ] Existing Shift/Caps, text, Delete, Esc/arrows, and trackpad behavior remains intact
- [ ] Tests, design lint, simulator Debug, arm64 Release, archive checks, and target-iPad acceptance pass

## Task 06 follow-up — missing Tab key

### Goal

Turn the existing visible `tab` placeholder into a real HID Tab key without changing its accepted geometry, label, alignment, or the single HID/Sticky routing architecture.

### Phase 37 — Tab mapping and integration

**Status:** complete

- Verify the Tab usage against the installed Apple HID usage declaration.
- Add Tab to the existing HID enum and `KeyKind` mapping only; reuse generic HID down/up/cancel handling and Sticky consumption.
- Enable the existing `tab` key spec in place and give it the same functional-key accessibility behavior as Esc/arrows.

### Phase 38 — Simulator visual and regression validation

**Status:** complete

- Regenerate the project and run the complete shared suite, design lint, diff/shell checks, and the existing iPad Pro 2018 simulator Debug build.
- Install/launch the simulator app and visually verify that Tab keeps the accepted 1.5-unit lower-left geometry, lowercase leading legend, functional-key color, and enabled appearance.
- Rebuild the `0.7.0 (16)` TIPA only if source changes alter the deliverable, then report the new artifact hash.

### Tab follow-up checklist

- [x] Visible Tab key is enabled without moving or resizing
- [x] Tab emits HID down/up and handles outside/cancel cleanup
- [x] Held and Sticky modifiers combine with Tab through the existing path
- [x] Tab completion consumes Sticky modifiers
- [x] iPad Pro 2018 simulator visual state matches `DESIGN.md`
- [x] Tests, lint, builds, archive checks, and Git cleanliness pass

## Task 06 bugfix — modifier toggle system conflicts

### Goal

Prevent a clean modifier tap from leaving a raw HID modifier held long enough to activate iPadOS system overlays or accessibility commands, while preserving the user-selected subset of physical multi-touch and/or one-shot modifier behavior.

### Phase 39 — System-behavior research and scope decision

**Status:** complete

- Confirm the reported Command shortcut-guide behavior against Apple documentation and the local held/Sticky state transitions.
- Evaluate Control and Option against iPadOS accessibility and modifier-key behaviors.
- Obtain the user's explicit scope choice before changing the established Task 06 interaction contract.

**Error recorded:** the first `autocli google search` invocation used the skill example's `--query` option, but the installed CLI requires a positional keyword. The corrected positional form completed all searches successfully.

### Phase 40 — Focused state repair and validation

**Status:** complete

- Add or revise focused modifier-state tests for the approved toggle policy, then apply the smallest compatible state/controller change.
- Verify physical multi-touch release, cancellation, lifecycle cleanup, visual state, shared tests, design lint, simulator behavior, arm64 packaging, and archive integrity.

**Approved policy:** remove tap-to-Sticky from all five Ctrl/Option/Command keycaps and retain physical multi-touch holding only.

### Modifier-toggle bugfix checklist

- [x] Left/right Command taps send HID key-up and cannot open the shortcut guide by remaining held
- [x] Control and left/right Option taps send HID key-up and cannot remain as raw accessibility activation modifiers
- [x] Physical multi-touch modifier down/up behavior remains intact
- [x] Outside/cancel, lifecycle, focus, and input-mode cleanup still converge on `rsthid()`
- [x] Held-state cyan highlight and “已按下” accessibility value remain; obsolete “已锁定” state is removed
- [x] Shared tests, design lint, simulator Debug, simulator interaction, arm64 Release, archive checks, and Git cleanliness pass
