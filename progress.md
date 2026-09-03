# MagicBoard Progress

## 2026-08-31 — Task 01 started

- Read and applied the `design-md` and `planning-with-files` skills.
- Confirmed the project directory was empty.
- Initialized Git and created baseline commit `f4009ce`.
- Completed design interview item 1/8: Overview.
- Created persistent planning, findings, and progress files.
- Next: design interview item 2/8 (Colors); implementation remains intentionally blocked until all required design and technical decisions are aligned.

## 2026-08-31 — Design interview completed

- Used `request_user_input` continuously as requested and completed items 2–8 of the fixed design interview.
- Confirmed customizable cyan-orange themes, system typography, adaptive layout, glass depth, continuous corners, installation/test components, and restrained native visual boundaries.
- Created `DESIGN.md` from the confirmed answers.
- Validated `DESIGN.md` with `npx --yes @google/design.md lint DESIGN.md`: 0 errors, 0 warnings, 0 infos.
- Next: align technical stack and device/TrollStore constraints before reference research or implementation.

## 2026-08-31 — Technical alignment started

- Detected Xcode 16.3 and Swift 6.1 locally.
- Confirmed SwiftUI for the host app, UIKit/`UIInputViewController` for the keyboard extension, and Swift for the shared module.
- Confirmed the acceptance environment family as iPadOS 16.x with TrollStore 2.
- Bundle Identifier selection returned empty through three direct prompts and one blocker-handling prompt.
- No Xcode project, reference clone, identifier, or implementation change was made while the identifier remains unresolved.
- Next: obtain a non-empty Bundle Identifier decision through `request_user_input`, then continue technical alignment.

## 2026-08-31 — Technical alignment completed

- Confirmed the identifier suite, iPadOS 16.0 target, XcodeGen strategy, local Swift Package, and user-operated iPad acceptance flow.
- Authorized Homebrew installation of XcodeGen; installation has not run yet.
- Started GitHub reference discovery through the `autocli gh` passthrough.
- The first two repository searches failed before returning results because this `gh` version does not support JSON field `nameWithOwner`; corrected future queries to use `fullName`.

## 2026-08-31 — Reference shortlist prepared

- Compared TrollStore upstream, Geranium packaging, Hamster's app/keyboard/App Group structure, KeyboardKit's demo, and XcodeGen upstream.
- Narrowed the proposed clone list to four repositories and documented license/adaptation boundaries in `findings.md`.
- Confirmed through Apple documentation that a non-Full-Access keyboard can read, but cannot write, the containing app's shared group container.
- `RequestsOpenAccess` selection returned empty three times and remains unresolved.
- Reference-clone authorization returned empty three times; no repository was cloned.
- Installed the explicitly authorized XcodeGen 2.46.0 Homebrew formula and verified its version.
- Next: obtain non-empty answers for the reference shortlist and `RequestsOpenAccess`; then add `/refrence` to `.gitignore`, clone approved repositories, and write `/refrence/refrence.md` before implementation.

## 2026-08-31 — Expanded reference set approved

- Confirmed `RequestsOpenAccess = true`; Task 01 must guide the user to enable Full Access and must communicate that the keyboard can write shared data and access the network entitlement surface.
- User requested more real keyboard implementations rather than approving the original four-repository set.
- Searched GitHub keyboard topics and inspected licenses, activity, adoption signals, and target structures.
- Expanded and approved an 11-repository set with seven real keyboard implementations; analysis remains capped below the 20-repository limit.
- Next: commit these decisions, add `/refrence` to `.gitignore`, shallow-clone the approved repositories, and produce `/refrence/refrence.md` before implementation.

## 2026-08-31 — Reference analysis completed

- Added and committed `/refrence/` to `.gitignore` before cloning.
- Shallow-cloned all 11 approved repositories successfully.
- Verified each local clone's HEAD, license, target files, entitlements, keyboard Info.plist, deployment target, project-generation approach, and relevant controller/build structure.
- Created `/refrence/refrence.md` with per-repository reusable methods, MagicBoard integration approach, borrowing level, license boundaries, and the final combined design.
- Corrected research metadata: TrollStore is MIT; KeyboardKit's local LICENSE is closed-source.
- Confirmed local `ldid` 2.1.5_1 is already installed and TrollStore upstream preserves per-binary entitlements applied by `ldid`.
- Phase 2 is complete. Next: confirm the deterministic pre-signing policy, then start the project scaffold.

## 2026-08-31 — Implementation prerequisites completed

- Confirmed deterministic signing: build with code signing disabled, then use local `ldid` to sign the host and keyboard executables separately with target-specific entitlements.
- Queried the required CodeGraph server; it reported that the project was not initialized.
- User authorized `codegraph init` and chose to commit the generated `.codegraph/.gitignore`; the local database remains ignored.
- Phase 1 and Phase 2 are complete. Phase 3 begins after indexing the project.

## 2026-08-31 — Scaffold implementation started

- Added XcodeGen app/keyboard targets, explicit Info.plists and App Group entitlements, a local shared Swift Package with four tests, SwiftUI installation UI, UIKit test keyboard, and a Zsh `.tipa` builder.
- Plist validation, project generation, target/scheme discovery, and all four shared-package tests passed.
- First simulator build failed in `KeyboardViewController.swift` with exit 65; verbose output was truncated before the compiler diagnostic, so no code fix has been attempted yet.

## 2026-08-31 — Local build and TrollStore package completed

- Captured direct evidence of a Swift 6.1 IRGen crash in `bldkbd()` and removed the associated-value key layout that triggered it; the replacement uses explicit UIKit rows and preserves text, space, delete, return, and system globe-key behavior.
- Rebuilt the complete app for arm64 iOS and both simulator architectures successfully.
- Re-ran the shared package suite: 4 tests passed, 0 failed.
- Made `project.yml` the single source of truth for host/keyboard Info.plists, App Group entitlements, Bundle Identifiers, and iPad-only device targeting.
- Added and verified the Zsh packaging flow: unsigned Xcode build, staged payload, per-binary `ldid` signing, metadata checks, and archive integrity checks.
- Generated `build/MagicBoard.tipa` (89,158 bytes), final HEAD rebuild SHA-256 `f8f908f279b275f18b35e2f788a1fa4ab0b337b62d13c655e60c49300549e8ce`.
- Verified both Mach-O executables are arm64, both signed entitlements contain `group.com.iwmei.magicboard`, the keyboard extension point is `com.apple.keyboard-service`, and `RequestsOpenAccess` is true.
- Reindexed CodeGraph: 6 files, 58 nodes, 109 edges; structural inspection confirmed the host and keyboard both load `BoardTheme` through `SharedConfig`.
- Phase 3 through Phase 5 are complete. Phase 6 requires the user's TrollStore installation and iPad Settings/keyboard UI acceptance evidence.

## 2026-08-31 — Device acceptance completed

- User confirmed through the structured acceptance prompt that TrollStore installation succeeded.
- User confirmed MagicBoard could be added in iPadOS Settings.
- User confirmed switching to MagicBoard displayed the test keyboard and its input controls worked normally.
- All Task 01 completion checks are now satisfied.

## 2026-08-31 — Task 02 started

- Re-read the existing `DESIGN.md`; its adaptive native test-keyboard rules apply without changes.
- Restored `task_plan.md`, `findings.md`, and `progress.md`; the session catch-up script reported no unsynchronized work.
- Verified a clean Git worktree before Task 02 changes.
- Used CodeGraph to confirm the current input path is `bldkbd → mkrow → mktext → puttxt → textDocumentProxy` and that the keyboard controller is the minimal UI change surface.
- Confirmed the 14-inch M-series MacBook Pro non-numpad QWERTY layout as the reference. Unsupported function/system keys are disabled placeholders for Task 03.
- Phase 7 is complete; Phase 8 begins with a testable input state model.

## 2026-08-31 — Task 02 input model completed

- Added `BoardPage` and `InputState` to the existing shared module without introducing a dependency.
- Defined physical-keyboard case behavior as `shifted != capsLocked`; single Shift is consumed only after a letter output, while Caps Lock persists.
- Added tests for single Shift, Caps Lock, Caps+Shift lowercase override, and letter/number/symbol page transitions.
- Ran `swift test --package-path Packages/MagicBoardShared`: 8 tests passed, 0 failed.
- Phase 8 is complete; Phase 9 begins with the MacBook Pro-inspired UIKit layout and proxy action wiring.

## 2026-08-31 — Task 02 keyboard implementation completed

- Replaced the Task 01 test rows with letter, number, and symbol pages modeled after the non-numpad 14-inch MacBook Pro typing area.
- Wired text, Space, Delete, Return, Shift, Caps Lock, page switching, and the system next-keyboard selector through `UIInputViewController` and `textDocumentProxy`.
- Kept the function row and unsupported macOS modifier keys disabled as explicit Task 03 placeholders.
- Added Shift alternate-symbol coverage; the shared package now passes 9 tests with 0 failures.
- Generated the Xcode project and built the complete host app plus keyboard extension for the iPad simulator successfully.
- Rechecked CodeGraph after implementation: 6 files, 93 nodes, and 96 edges; the controller routes text emission through `InputState` before calling the document proxy.
- Phase 9 is complete. Phase 10 proceeds with the arm64 TrollStore package and on-device acceptance.

## 2026-08-31 — Task 02 TrollStore package generated

- Built the complete Release app and keyboard extension for generic iOS arm64 from source commit `73ca17e`.
- Generated `build/MagicBoard.tipa` (107,453 bytes), SHA-256 `b8c33cc00a87dace86dfe501c2486dc71c0744797f8166d548397484a2196cdf`.
- Verified ZIP integrity, arm64 Mach-O host/extension binaries, Bundle Identifiers, `com.apple.keyboard-service`, and `RequestsOpenAccess = true` from a fresh archive extraction.
- Verified both embedded executables carry the `group.com.iwmei.magicboard` App Group entitlement.
- Local Phase 10 checks are complete; on-device TrollStore installation and behavioral acceptance remain.

## 2026-08-31 — Task 02 stale-extension diagnosis and versioned rebuild

- Inspected the user's device screenshot and matched its visible status label and four-row structure exactly to the Task 01 controller; the current Task 02 source no longer contains those elements.
- Verified the existing Task 02 archive binary contains new-only function-row assets (`sun.min`, `playpause.fill`, and `arrow.left.and.right`), proving the screenshot was rendered by the old installed extension.
- Inspected TrollStore's local source: overwrite installation replaces the full app bundle and registers embedded plugins, while Refresh App Registrations re-registers all TrollStore apps and resprings.
- Found that XcodeGen's Info.plist generator defaults to `1.0 (1)` unless version keys are explicitly provided; this made Task 01 and Task 02 indistinguishable in TrollStore.
- Mapped both target plists to the shared build settings, bumped Task 02 to `0.2.0 (2)`, and added package checks requiring host/extension version parity.
- Re-ran 9 shared tests successfully and generated `build/MagicBoard.tipa` (107,459 bytes), SHA-256 `461fda52c3b4898299558716c87cc2c95176549d9867c88b075612657179cb1d`.
- Fresh extraction verified both host and extension are arm64 and report `0.2.0 (2)`; device installation and refreshed screenshot remain pending.

## 2026-09-01 — Task 02B started

- Read and applied the `request-user-input`, `design-md`, and `planning-with-files` skills.
- Confirmed the required interaction decisions: latched Shift long-hold releases to off, Delete repeats at 450/80 ms, and down-drag triggers at 24 pt while continuing outside the original key.
- Verified the repository is clean at requested HEAD `2881955` and read the existing accepted `DESIGN.md`.
- Added Task 02B phases and explicit success checks to the existing persistent plan; no source or design changes have been made yet.
- Next: use CodeGraph to map the existing state and proxy-action flows, then add tests before implementation.

## 2026-09-01 — Task 02B impact analysis completed

- Used CodeGraph context, symbol source, and impact queries to identify the shared state model and controller touch binding as the only required source change surfaces.
- Confirmed all current text insertion is centralized through `InputState.emit` and `textDocumentProxy.insertText`; the repair will extend these existing paths rather than add a parallel input engine.
- Confirmed Delete currently handles only `.touchUpInside`, while `BoardButton` has no per-touch state and the controller has no repeat timer lifecycle.
- Recorded a CodeGraph symbol-line mismatch for nonexistent `setshft`/`altout` metadata; live source snippets, compilation, and tests remain authoritative.
- Next: inspect the exact shared tests and controller lifecycle, then write failing state-machine tests before implementation.
- A combined read used stale guessed test/script paths and reported three not-found errors; the same command resolved the correct paths, so no fallback shell or repeated failing command is needed.
- Read the resolved shared tests and Zsh packaging script and verified project version `0.2.2 (11)`.
- Verified UIKit control events, Foundation timer invalidation/common-mode scheduling, and pan gesture terminal states against Apple Developer documentation before using those APIs.
- Verified the project has no forbidden local macOS shell invocation.
- Inspected the approved Tasty reference implementation for repeat-delete and Shift touch tracking; selected its event lifecycle while simplifying its two timers to one owned timer and retaining MagicBoard's existing state/document-proxy paths.

## 2026-09-01 — Task 02B Shift tests added

- Added boundary tests for Shift touch-down/up/cancel, latched Shift re-press, held multi-character input, Caps Lock XOR behavior, Chinese alternate symbols, and modifier-independent drag output.
- Ran the shared suite and received the expected compile failures for the four not-yet-implemented transition APIs; no pre-existing test failure appeared before those missing members.
- Next: implement the minimum shared state fields and transitions, then rerun the full shared suite.

## 2026-09-01 — Task 02B shared state completed

- Added touch-start, touch-start-state, and held-input tracking to the existing `InputState` value type.
- Added `shftdown`, `shftup`, `shftcncl`, and `dragout` transitions without changing language or Caps Lock APIs.
- Preserved ordinary one-shot Shift behavior when no Shift touch is active and kept held Shift active across multiple emitted characters until release.
- Ran the complete shared package suite: 20 tests passed, 0 failed.
- Phase 11 and Phase 12 are complete. Phase 13 begins with controller event wiring and lifecycle cleanup.

## 2026-09-01 — Task 02B controller wiring compile pass 1

- Wired Shift control events, Delete repeat stop events, and one pan recognizer per text key while preserving every existing layout/style `KeySpec` value.
- Re-ran all 20 shared tests successfully and regenerated the Xcode project.
- The requested 2018 simulator Debug build reached `KeyboardViewController.swift` and failed only because Swift 6 forbids direct MainActor UIKit access from `Timer` Sendable closures.
- Next: make the two timer callbacks hop explicitly to `@MainActor`, retain the timer-validity guard, and rebuild once.
- The callback isolation fix compiled; pass 2 then stopped at controller `deinit`, where Swift 6 cannot prove the main-RunLoop-confined `Timer?` is safe to access from a nonisolated destructor.
- Next: annotate only the timer storage as manually main-thread confined, keep deinit invalidation, and rebuild without changing behavior.

## 2026-09-01 — Task 02B controller implementation completed

- Confined the single Delete timer to the main RunLoop, retained deinit invalidation, and explicitly hopped Sendable timer callbacks to MainActor with validity checks.
- Built Debug successfully for simulator `73860E49-6DDF-450B-B505-F0E0A09F764B`; only unrelated AppIntents metadata warnings were emitted.
- Installed and launched the current Debug app, switched Safari to MagicBoard, and visually confirmed the accepted six-row Mac layout remains intact.
- Safari address-bar automation passed normal text, one-shot Shift, left/right Shift toggle equivalence, shifted punctuation, one-character Delete, language switching, and Chinese base/alternate punctuation.
- Simulator mouse bridging could not faithfully generate held multi-touch, long press, or system touch-cancel, and produced inconsistent pan delivery; those physical-touch cases remain for device acceptance.
- Phase 13 is complete. Phase 14 continues with diff/design validation, Release arm64 build, packaging, and final artifact inspection.

## 2026-09-01 — Task 02B final validation pass 1

- `DESIGN.md` lint returned 0 errors, 0 warnings, and 0 infos.
- The full shared package suite passed again: 20 tests, 0 failures.
- Generic iOS Release built both host and keyboard as arm64 and generated `MagicBoard.tipa` version `0.2.2 (11)`.
- ZIP integrity passed; artifact size is 118,097 bytes and SHA-256 is `1992028d9215a8db66d97ccf601bd122f1bbe779338ef6bdb4c873801c968403`.
- Byte comparisons confirmed the fixed key-layout/mapping block and existing UIButton configuration style block are identical to baseline `2881955`.
- A standalone `plutil` entitlement query used invalid dotted-key syntax; next verification will use the already-exported entitlement plists with PlistBuddy.

## 2026-09-01 — Task 02B local validation completed

- Re-read exported host and keyboard entitlement plists with PlistBuddy: both contain `group.com.iwmei.magicboard`; the keyboard extension point and open-access setting are correct.
- Final artifact is `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, version `0.2.2 (11)`, 118,097 bytes, SHA-256 `1992028d9215a8db66d97ccf601bd122f1bbe779338ef6bdb4c873801c968403`.
- Artifact implementation commit is `82f9db2`.
- All local automated acceptance items are complete. Physical touch validation remains for held multi-touch Shift, Delete hold/exit/cancel, and drag exit/cancel because Simulator mouse automation cannot faithfully synthesize those inputs.

## 2026-09-01 — Task 02B physical acceptance and visual follow-up

- User confirmed all functional Shift, Delete, down-drag, cancellation, and regression scenarios pass on the target device.
- User supplied three cropped keyframes showing the lower legend shrinking/fading while the upper alternate moves to center.
- Inspected all three images at original resolution and used CodeGraph to confirm only transient character-key presentation needs to change.
- Confirmed letters use uppercase/current-letter temporary layers and all gestures use continuous 0–24 pt progress plus a 120 ms restoration.
- Added the confirmed transient feedback rule to the existing `DESIGN.md`; static visual tokens and keyboard structure remain unchanged.
- Phase 14 is complete. Phase 15 begins with transient overlay implementation.

## 2026-09-01 — Down-drag visual implementation pass 1

- Added transient upper/lower UILabel storage to character buttons and interactive progress handling to the existing pan recognizer.
- Added endpoint restoration for lowercase/uppercase letters, unshifted/shifted symbols, success, and cancellation without changing static configuration.
- Shared tests remained green at 20/20.
- Simulator compilation found one isolated type-inference error where `27 / 22` became `Int` in a local reset scale; next pass will type that value as `CGFloat`.

## 2026-09-01 — Down-drag visual implementation completed

- Corrected the reset scale to explicit `CGFloat`; the requested 2018 simulator Debug build then succeeded.
- Added gesture-instance guards so rapid consecutive drags cannot be disrupted by an earlier 120 ms completion.
- Added Reduce Motion behavior: interactive drag remains, reset becomes immediate.
- Re-ran all 20 shared tests successfully and visually confirmed the static six-row keyboard remains unchanged after installing the updated Debug build.
- Recorded a Simulator drag and inspected its keyboard crop; mouse bridging did not expose reliable mid-touch frames, so final motion timing remains a target-device visual acceptance item.
- Phase 15 is complete. Phase 16 proceeds with final lint, baseline comparison, Release packaging, and artifact inspection.

## 2026-09-01 — Down-drag visual validation completed

- Re-ran `DESIGN.md` lint with 0 errors, 0 warnings, and 0 infos.
- Re-ran the complete shared package suite: 20 tests passed, 0 failed.
- Confirmed the only lines removed from the accepted controller baseline are superseded event-path statements; no layout, typography, color, icon, alignment, symbol-map, or six-row structure definition was removed or rewritten.
- Rebuilt the generic iOS Release with the existing `ldid` TrollStore packaging flow; both host and keyboard extension are arm64 and retain `group.com.iwmei.magicboard`.
- Verified ZIP integrity and regenerated `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, version `0.2.2 (11)`, 121,836 bytes, SHA-256 `dab6ec42cc5aa55be52038a0aa34906685863bd3eae45f04d37bdbf98182b25c`, from implementation commit `31efbc5`.
- All locally automatable checks are complete. Target-device visual comparison against the three supplied motion frames remains the final acceptance item.

## 2026-09-01 — Down-drag visual accepted on target device

- User installed the regenerated TIPA on the MagicBoard iPad Pro 12.9 2018 and confirmed the complete down-drag motion matches the supplied reference frames.
- Task 02B and its down-drag visual follow-up are fully accepted; no further code or package change is required.

## 2026-09-02 — Task 04 started

- Verified the repository is a clean Git worktree on `master` at `3627d2b` before any change.
- Restored the existing planning files and confirmed CodeGraph is healthy with 6 indexed files, 127 nodes, and 130 edges.
- Initially found no functional Esc/arrow key kinds and asked the user to resolve the apparent Task 03 baseline mismatch.
- User clarified that Task 03 was layout-only and was implemented inside commits currently labeled as Task 02; HID behavior is correctly deferred to Task 04.
- Added Task 03 scope clarification plus four Task 04 phases and explicit completion checks.
- Backed up the pre-edit planning files under `/Users/mac/backup/2026-09-02_1600_MagicBoard_HID04/`.
- Next: inspect TrollVNC source and verified private HID API/entitlement declarations before designing `HIDBridge`.

## 2026-09-02 — Task 04 research completed

- Shallow-cloned `OwnGoalStudio/TrollVNC` commit `170c784` into ignored `refrence/TrollVNC` and analyzed its GPL source without copying it.
- Confirmed the native IOKit event sequence, sender ID, five HID usages, framework link, and direct private C signatures.
- Compared TrollVNC's broad entitlements with extracted iOS 16–18 system entitlements and selected only `com.apple.private.hid.client.event-dispatch` for the keyboard target.
- Verified both device and simulator SDK stubs export the selected private IOKit symbols.
- Used CodeGraph to constrain local source changes to the existing placeholder specs and controller routing; no shared state or host-app service is affected.
- Phase 17 is complete. Phase 18 starts with the independent Objective-C `HIDBridge` and paired down/up lifecycle.

## 2026-09-02 — Task 04 implementation and package completed

- Added the independent `HIDBridge` Objective-C module, direct IOKit link, Swift bridge header, five HID usage mappings, paired touch lifecycle, active-key deduplication, and release-all cleanup.
- Enabled only Esc and the four direction keys; retained all Task 03 positions and weights and left the remaining placeholders disabled.
- Added only `com.apple.private.hid.client.event-dispatch` to the keyboard target and extended package validation to enforce keyboard-only privilege placement.
- Bumped the package to `0.4.0 (12)`.
- Re-ran 20 shared tests successfully and built the full simulator Debug target successfully.
- Built and signed the arm64 Release package successfully; independent archive, Mach-O, version, entitlement, IOKit-link, and imported-symbol checks all passed.
- Artifact: `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, 126,212 bytes, SHA-256 `93681916a6c0e9e666e3ecbb477dcd674b603a937da4be469adf6453ad28d279`.
- Phases 18 and 19 are complete. Phase 20 requires target-device installation and tests in two foreground apps plus an Esc-aware app.
- Re-read the accepted `DESIGN.md`; functional-key state styling already covers the five newly enabled keys, so no design-file change was required.
- Ran the design lint with 0 findings and confirmed the post-write CodeGraph index is healthy.

## 2026-09-02 — Task 05 cursor model completed

- User accepted four-direction HID cursor movement at a 0.45-second activation threshold and approximately 12 points per arrow step.
- User refined the visual requirement to the native full-keyboard trackpad state; Apple guidance confirms the keyboard becomes light gray while dragging the insertion point.
- Added and verified the shared cursor-motion model after an expected missing-symbol red test phase.
- The shared suite now passes 25 tests with 0 failures. Phase 23 proceeds with the Space recognizer, full-key-grid overlay, HID pairing, and cleanup.

## 2026-09-02 — Task 05 controller wiring completed

- Added the Space-only long-press recognizer while preserving the existing short-tap document-proxy action.
- Added the uninterrupted dynamic light-gray overlay covering the complete keyboard extension surface during active cursor mode; release/cancellation restores the underlying accepted keyboard immediately.
- Wired dominant-axis cursor steps to paired left/right/up/down HID events and added cleanup to rebuild and disappearance lifecycles.
- Re-ran 25 shared tests successfully and completed the 2018 iPad Pro simulator Debug build. Phase 24 continues with versioning, Release packaging, archive verification, and target-device acceptance.

## 2026-09-02 — Task 05 local validation completed

- Bumped the app and extension to `0.5.0 (13)` and regenerated the Xcode project.
- Final design lint reported 0 findings; all 25 shared tests and the 2018 iPad Pro simulator Debug build passed.
- Generic arm64 Release packaging and all built-in entitlement/version checks passed.
- Independently verified ZIP integrity, arm64 binaries, host/extension version parity, IOKit linkage, HID imports, and least-privilege entitlement placement.
- Artifact: `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, 133,233 bytes, SHA-256 `b860067117cb7c77afc9addd82ed0da12c9f2a66490e9de7501845da4d821f64`, source commit `6cfc02e`.
- Phase 24 now awaits target-iPad touch acceptance in two text editors.

## 2026-09-02 — Function 05 modifier work started

- Verified a clean Git worktree at `fcd7ba6`, restored the existing planning files, and confirmed CodeGraph is healthy with 8 indexed files.
- Re-read the accepted `DESIGN.md`; existing functional-key and selected-state rules cover the requested modifier enablement without a design-file change.
- Mapped the existing `InputState`, `prskey`, key-spec factories, and sole `HIDBridge` lifecycle. No second HID engine or shortcut-command table is needed.
- Verified A–Z and five physical modifier usages against the installed Apple IOKit usage-table declarations.
- Backed up the pre-edit planning files under `/Users/mac/backup/2026-09-02_功能05_修饰键/`.
- Added Phases 25–28 and explicit foreground-app acceptance checks. Phase 25 proceeds with red tests for the shared `ModifierState`.
- Added five focused state tests. The first shared-suite run failed at compile time only on the intentionally missing `ModifierState`/`ModifierKey` symbols, establishing the expected red phase with no unrelated regression.
- Added the minimum shared `ModifierKey`/`ModifierState` model with five physical sources, idempotent press/release, active queries, and full reset.
- Re-ran the complete shared suite: 30 tests passed, 0 failures. Phase 25 is complete; Phase 26 begins with the existing HID bridge and controller routing only.
- Extended the existing HID enum with verified A–Z, number, punctuation, Space, Return, Delete, and five physical modifier usages; no bridge implementation or entitlement change was needed.
- Enabled the existing Control/Option/Command keycaps without moving or resizing them, added held-state feedback, and wired down/up/outside/cancel/drag-exit cleanup.
- Centralized modified character dispatch so active modifiers use paired HID events and return before `textDocumentProxy`; Space, Return, and Delete follow the same rule, while unmodified input remains unchanged.
- The first simulator build exposed the verified Clang Importer spelling `.A...Z`; a direct Swift type check confirmed it, the source was corrected, and the complete 2018 iPad Pro simulator Debug build then succeeded.
- A first type-check probe used literal `\\n` separators and failed at its own syntax; the semicolon-delimited probe succeeded. The first post-write CodeGraph status call returned `Transport closed` and will be retried during final validation.
- Re-ran all 30 shared tests successfully and found no prohibited local Shell invocation. Phase 26 is complete; Phase 27 starts with version `0.6.0 (14)`, lint, Release packaging, and archive inspection.

## 2026-09-02 — Function 05 local validation completed

- Committed the modifier implementation as `ae5cb5c` and regenerated the project at version `0.6.0 (14)`.
- Final shared suite passed 30/30; `DESIGN.md` lint reported 0 errors, warnings, or infos; the 2018 iPad Pro simulator Debug build and generic arm64 Release build succeeded.
- Static inspection found no select/copy/paste/undo implementation or Command+A/C/V/Z command table; MagicBoard only chooses proxy versus HID transport based on active physical modifiers.
- Generated `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, 146,567 bytes, SHA-256 `24e7c4f2df768cf422b540b3381758225ea4febb63a842b25f0e38707670ea29`.
- Independent archive validation passed ZIP integrity, arm64 architecture, host/extension `0.6.0 (14)` parity, IOKit linkage, four HID imports, and least-privilege entitlement placement.
- The independent verification command was initially rejected before execution because it included temporary-directory deletion; the read-only variant passed and left `/tmp/magicboard-verify.NdcwmH` intact.
- Post-write CodeGraph status retries both returned `Transport closed`; the successful pre-write context plus compiler/test/archive evidence remain authoritative for this turn.
- No target iPad is connected through `devicectl`, so Phase 27 is complete and Phase 28 awaits installation plus foreground-app acceptance for Command+A/C/V/Z, one app-specific Command shortcut, and Control/Option combinations.

## 2026-09-02 — Function 05 accepted; held-Shift bug diagnosed

- User confirmed the complete Function 05 modifier acceptance checklist passes perfectly on the target iPad, completing Phase 28.
- User reported a new reproducible bug: holding Shift while pressing direction keys moves the caret instead of continuously selecting text.
- Verified a clean Git baseline at `f50a642`, restored planning/history context, and re-read the accepted `DESIGN.md`.
- CodeGraph and direct source inspection prove Shift exists only in proxy-oriented `InputState`; no Shift HID event is sent, while arrows send only their own HID usage.
- Confirmed the second state defect: arrow use never marks `shftused`, so the release transition can incorrectly preserve a one-shot Shift state after the chord.
- Verified Left/Right Shift usages `0xE1/0xE5` against the installed Apple IOKit declarations.
- User approved a thorough state-machine repair after root-cause and impact disclosure. Added Phases 29–31; Phase 29 proceeds with focused failing tests before implementation.

## 2026-09-02 — Held-Shift HID repair completed locally

- Added four focused tests before implementation. The expected red run failed only on the missing `ShiftKey`, `shiftHeld`, and `shftuse` APIs; the completed shared suite passes 34/34.
- Replaced the single held Boolean with independent left/right Shift sources while preserving the existing one-shot and proxy character semantics.
- Mapped the existing Shift keycaps to real Left/Right Shift usages `0xE1/0xE5` and wired touch down/up/cancel to the sole existing `HIDBridge`.
- Marked held Shift used when arrows, trackpad directions, Delete, ordinary controls, or Control/Option/Command chords begin, preventing an unwanted Shift latch after a chord.
- `xcodegen`, `DESIGN.md` lint, prohibited-Shell scan, iPad Pro simulator Debug, generic arm64 Release, and `git diff --check` pass.
- Generated `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` at `0.6.1 (15)`, 149,696 bytes, SHA-256 `628efef7b280951ad946cf1af8377ec98cd9d2a875eeb6c42fced4b319bc462e`.
- Independent extraction confirms ZIP integrity, arm64 host/extension binaries, matching version/build, four expected IOKit HID imports, host App Group entitlement, and keyboard App Group plus HID event-dispatch entitlement.
- Phases 29–31 are complete. Phase 32 remains for target-iPad Shift+arrow continuous-selection and regression acceptance.

## 2026-09-02 — Task 06 started

- Verified a clean Git worktree at `43f2ee1` and re-read the accepted `DESIGN.md`.
- Used CodeGraph to identify the existing shared `ModifierState`, controller touch handlers, visual update path, and sole HID bridge as the complete Task 06 change surface.
- Applied the `design-md` and `planning-with-files` skills; the existing selected-key visual rule covers Sticky highlighting without changing `DESIGN.md`.
- Backed up `task_plan.md`, `findings.md`, and `progress.md` under `/Users/mac/backup/2026-09-02_任务06_Sticky_Modifier/` before this planning update.
- Added Phases 33–36 with explicit state-machine, lifecycle, build/package, and target-iPad success checks.
- The minimum design distinguishes held, Sticky, and used physical touches; modifier taps combine, the same Sticky key toggles off, and only a successfully completed non-modifier HID key consumes Sticky state.
- Phase 33 proceeds with focused failing tests before the shared state implementation.

## 2026-09-02 — Task 06 modifier model completed

- Added six focused Sticky tests before implementation; the expected red run failed only on the five new transition/query APIs.
- Replaced the single active set with held, Sticky, and used source sets while preserving the existing `press`, `release`, `contains`, and `reset` contract.
- Added tap-to-lock, tap-again unlock, cancellation restoration, multi-Sticky consumption, physical-chord use, and held-source preservation transitions.
- Re-ran the complete shared suite: 40 tests passed with 0 failures. Phase 33 is complete and Phase 34 is in progress.

## 2026-09-02 — Task 06 controller wiring completed

- Split successful modifier taps from outside/cancel/drag-exit endings so only a clean tap can create or toggle Sticky state.
- Added per-button HID completion tracking and consume Sticky modifiers only after successful non-modifier HID key-up; physical held modifiers remain down until their own touch ends.
- Reused the existing cyan selected state for held and Sticky modifiers and added selected accessibility traits plus “已按下”/“已锁定” values.
- Centralized Shift/modifier state reset, HID `releaseAll`, timer/trackpad cleanup, and keycap refresh in one idempotent path.
- Wired that reset to rebuild, dismissal, system next-keyboard touch-down, view disappearance, and extension-host resign/background notifications.
- The first two simulator compiles identified the exact Swift-imported extension notification names; the compiler-declared names resolved the issue and the complete arm64/x86_64 simulator Debug build passed.
- Re-ran all 40 shared tests, `git diff --check`, and the prohibited local-Shell scan successfully. Phase 34 is complete and Phase 35 is in progress.

## 2026-09-02 — Task 06 local validation completed

- Bumped both targets to `0.7.0 (16)`, regenerated the Xcode project, and committed the version change at `0e7340d` after the implementation commit `6d9fc58`.
- Final verification passed: 40/40 shared tests, zero `DESIGN.md` lint findings, M1 12.9-inch iPad Pro simulator Debug, generic arm64 Release, `git diff --check`, and the prohibited local-Shell scan.
- Generated `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, 158,950 bytes, SHA-256 `3d9244cb477865157d44eb76b9599a3b368c50298c6836b0fdcd24b59b6c87d9`.
- Independent archive checks passed ZIP integrity, arm64 architecture, host/extension `0.7.0 (16)` parity, extension identity/open access, IOKit linkage/imports, and least-privilege entitlement placement.
- The first entitlement pipeline could not feed the codesign representation into `plutil`; direct codesign entitlement display provided the required independent evidence without repeating the failed approach.
- CodeGraph is healthy after implementation with 8 indexed files, 206 nodes, and 416 edges; the Git worktree was clean before this final planning/history update.
- No target iPad is connected through `devicectl`. Phase 35 is complete; Phase 36 remains for physical multi-touch, input-mode/focus/lifecycle cleanup, and regression acceptance.

## 2026-09-02 — Task 06 Tab follow-up started

- User identified that the visible Tab key had remained an unimplemented placeholder throughout earlier work and requested simulator-based visual verification where TrollStore is unnecessary.
- Verified a clean Git worktree, re-read `DESIGN.md`, and used CodeGraph to confirm Tab is absent from `KeyKind` and the HID mapping.
- Backed up the planning files under `/Users/mac/backup/2026-09-02_任务06_Tab补齐/` and added Phases 37–38.
- The minimal repair will enable the existing 1.5-unit lowercase leading Tab key in place and reuse generic HID/Sticky handling; Phase 37 is in progress.

## 2026-09-02 — Task 06 Tab follow-up completed

- Added the verified Keyboard Tab HID usage `0x2B`, a `KeyKind.tab` mapping, the existing generic enabled-control spec, and a Tab accessibility label; no layout, state-machine, or bridge implementation was duplicated.
- Re-ran all 40 shared tests, `DESIGN.md` lint, diff/Shell checks, and the existing iPad Pro 2018 simulator Debug build successfully.
- Installed the build in the simulator and visually confirmed unchanged Tab geometry, label alignment, and enabled functional-key color. A Ctrl Sticky tap highlighted Ctrl, and completing Tab automatically cleared it.
- Committed the source repair as `351ee21`, rebuilt the arm64 TrollStore package, and independently verified archive integrity, versions, architecture, HID imports, and entitlement placement.
- Final artifact: `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, version `0.7.0 (16)`, 159,680 bytes, SHA-256 `6be54d51d8f3ca5eeecd2177083a5d32d4ba1d4eb4fa19a226e560c25d745bd4`.

## 2026-09-02 — Task 06 modifier-toggle bug diagnosed

- User reported that tapping Command leaves it logically held and opens the iPadOS shortcut-guide overlay, then confirmed Command Sticky must be removed and requested an official iPadOS review before deciding Control/Option.
- Verified a clean Git baseline and found no runtime log evidence; CodeGraph directly identifies the clean-tap `held → sticky` transition as the complete cause.
- Official Apple guidance confirms held Command opens app shortcut guidance, held Control can activate Hover Text, Option or Command can be configured as the same activation modifier, and Control–Option can serve as the VoiceOver modifier.
- The installed `autocli` rejected the documented `--query` form once; its verified positional keyword form completed the official-source searches and page extraction.
- Added Phases 39–40. No product code has changed while the exact Control/Option policy awaits user confirmation.
- After one empty selection response, the repeated focused prompt succeeded: user chose to cancel Sticky for all modifiers and keep physical multi-touch only.
- Phase 39 is complete. Phase 40 starts with a failing clean-tap regression test, then removes only Sticky-specific state/controller paths while preserving Task 06 lifecycle cleanup.

## 2026-09-02 — Modifier toggle conflicts fixed

- Replaced six Sticky-specific tests with one five-source clean-tap regression. The expected red run produced 10 assertions only because every modifier remained active after tap.
- Removed Sticky/used state and its consume/accessibility/controller branches while preserving physical multi-touch down/up, cyan held highlighting, HID failure recovery, and the unified `rsthid()` lifecycle cleanup.
- Final shared suite passes 35/35; design lint, Shell scan, `git diff --check`, iPad Pro 2018 simulator Debug, and generic arm64 Release all pass.
- Simulator interaction confirms Command has no lingering highlight or shortcut-guide popup after three seconds, and Ctrl/Option also release immediately.
- The updated install reset Full Access; user approved restoring it and then manually switched to MagicBoard by holding/dragging the Globe key to the target input method, a gesture Computer Use could not reproduce reliably.
- Source committed as `1679abc`. Rebuilt `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` at `0.7.0 (16)`, 151,470 bytes, SHA-256 `c76b8342a46c430529c81f12b09551af10d1f0a02be9f98e0e1014f1bbc49074`.
- Phase 40 is complete; only Phase 36 target-device physical multi-touch and lifecycle acceptance remains.

## 2026-09-02 — Task 06 F1–F12 follow-up started

- Verified a clean Git worktree and completed a real Tab navigation test in the existing iPad Pro 2018 simulator: focus moved from Customer name to Telephone on a public form without submitting data.
- Re-read the accepted `DESIGN.md`, applied `design-md`, `planning-with-files`, `request-user-input`, and `computer-use`, and preserved the fixed top-row visual contract.
- User chose normal standard F1–F12 plus held-Shift icon actions.
- Verified the exact usages against Apple's installed HID table and found the existing TrollVNC page-aware Consumer HID implementation already present under `refrence/`.
- Backed up the three planning files under `/Users/mac/backup/2026-09-02_任务06_F1-F12/` before adding Phases 41–43. Phase 41 proceeds with the existing event bridge and paired touch lifecycle only.

## 2026-09-02 — Task 06 F1–F12 completed locally

- Added standard F1–F12 usages and twelve icon-layer system usages to the existing HID bridge; active-key cleanup is now page-aware without adding a second event client or entitlement.
- Enabled the accepted top row in place and routed held physical Shift to the icon layer while ordinary and one-shot-Shift touches continue to send standard F keys.
- Stored the selected icon usage per button at touch-down, paired its exact key-up on every touch ending, and included it in the existing unified lifecycle reset.
- Passed 35/35 shared tests, zero-finding design lint, diff checks, the iPad Pro 2018 simulator Debug build, and the generic arm64 Release package.
- Simulator visual inspection passed, and a browser key-code page reported direct MagicBoard F1/112, F6/117, and F12/123 events. Tab's earlier real form-focus navigation remains accepted.
- A failed address-field set was resolved by focusing the field first. A `Command-L` attempt locked iPadOS rather than focusing Safari; Space unlocked it and coordinate focus plus the settable accessibility value completed navigation. No project state was affected.
- Source implementation committed as `496cf91`. Final `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` is `0.7.0 (16)`, 151,842 bytes, SHA-256 `6ce6acd207b30f36b9bf115cb6c5cc15822be165b24020a8784aeafca3c31cd3`.
- Local archive, architecture, plist, IOKit import, and entitlement checks pass. Phase 44 remains for target-iPadOS 16.x physical Shift+F1–F12 and cancellation acceptance.

## 2026-09-02 — F-row dual-layer interaction refinement started

- User chose full consistency with dual-layer character keys: downward drag selects the icon action, and both one-shot and physically held Shift switch the row to the icon layer; Caps Lock does not affect it.
- CodeGraph isolated the change to `InputState`, the existing F key touch routing, and the existing drag overlay helpers.
- The current touch-down HID dispatch would misfire a standard F event before Pan recognition, so the approved repair defers each F tap to successful completion and emits a complete pair there.
- Added Phases 45–47 and focused red tests for successful F-layer Shift consumption before implementation.

## 2026-09-02 — F-row dual-layer interaction completed locally

- Added `InputState.usefn()` with two focused tests; the expected red run failed only on the missing transition, then the full suite passed 37/37 after implementation.
- Routed F1–F12 taps to successful touch completion and reused the existing Pan recognizer, 24-point threshold, progress transforms, and 120 ms reset. F cancellations now clear only the pending layer and emit no HID event.
- Generalized only the upper transient drag view so it can render each existing SF Symbol; the lower caption continues using the existing label path and accepted geometry.
- Simulator Debug acceptance passed: Shift shows icon-only F keys, F10 consumes one-shot Shift and restores the stack, Shift+F4 opens search, and ordinary F1 reports key code 112.
- Computer Use cannot synthesize the existing character-key Pan drag either, so final motion feel and down-drag dispatch remain explicit target-iPad touch checks.
- Source committed as `e66ea40`. Release packaging and independent inspection passed for `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, version `0.7.0 (16)`, 154,072 bytes, SHA-256 `bc8e7800c2fb55f8ab4a8f91c730753be420a34de9342c49d142fd59ca703125`.

## 2026-09-02 — Task 07 native visual refactor started

- Verified a clean Git worktree and re-read the complete `design-md` and `planning-with-files` instructions plus the existing `DESIGN.md`.
- Used CodeGraph before raw source inspection. The graph found the shared modifier/theme symbols but no `KeyView`; direct inspection then confirmed visual decisions are duplicated inside `mkkey`, `rfrshft()`, and `updmods()`.
- Preserved the accepted six-row Mac layout and all input behavior as frozen scope. Task 07 changes only the visual component, dynamic palette/state mapping, keyboard backdrop, spacing, and adaptive height.
- Backed up `task_plan.md`, `findings.md`, and `progress.md` under `/Users/mac/backup/2026-09-02_1500_MagicBoard_07/` before adding Phases 48–50.
- Phase 48 is complete. Phase 49 is in progress with `KeyView` as the single visual authority.

## 2026-09-02 — Task 07 KeyView implementation and simulator cleanup

- Replaced `BoardButton` with a single `KeyView` visual component. It owns semantic ordinary/function roles, normal/highlighted/selected/disabled state colors, dynamic light/dark palette, 7-point fixed corners, half-point border, crisp shadow, and Reduce Motion-aware pressed depth.
- Shift, Caps Lock, and physical Ctrl/Option/Command state refreshes now set `isSelected`; they no longer duplicate fill/foreground choices in the controller. All accepted legends, touch targets, gestures, and HID routing remain in place.
- Changed the keyboard backdrop to dynamic system chrome material plus a semantic gray overlay; tuned outer insets to 7/8/9 points, horizontal gaps to 6, row gaps to 7, arrow-pair gaps to 4, and adaptive height to `clamp(width × 0.5, 340, 430)`.
- Shared tests passed 37/37. The first simulator compile failed because `role` collided with UIKit's existing `UIButton.role`; renaming the property to `keyRole` fixed the issue, and the Debug build then succeeded on both the short-lived 13-inch M4 target and the preserved 2018 target.
- At the user's direction, deleted every CoreSimulator device except `MagicBoard iPad Pro 12.9 2018`. The first explicit delete stopped on one mistyped UDID after deleting the first target; re-listing and correcting the remaining exact UDIDs completed successfully. The 2018 device data remained intact.
- The preserved 2018 simulator initially showed black app scenes because system services were still loading. After the user-requested wait, Messages and the configured system keyboard reappeared normally; no erase/reset was performed. UI verification is continuing only on this device.

## 2026-09-02 — Task 07 portrait overflow correction

- The user identified severe portrait clipping on keys with two-line legends. At the temporary 340-point keyboard height, the 8/9-point outer insets and four 7-point row gaps left each of the six rows only about 47.5 points; after the button content insets, two 22-point legend lines could not fit safely.
- Restored the accepted width-derived height formula to `clamp(width × 0.5, 340, 430)`. The 2018 simulator now reaches 430 points in full-screen portrait and landscape, keeping both legend lines inside the keycaps.
- Rebuilt and reinstalled on the preserved 2018 simulator. Portrait light, portrait dark, active Shift, and landscape dark were visually checked; dynamic appearance switching, ordinary/function hierarchy, selected modifier contrast, spacing, and dual-line containment all remained intact.

## 2026-09-02 — Task 07 final validation and package

- Shared tests pass 37/37, `DESIGN.md` lint reports zero findings, the prohibited local-Shell scan is empty, `git diff --check` passes, and the sole simulator inventory entry remains `MagicBoard iPad Pro 12.9 2018`.
- XcodeGen regeneration, the 2018 simulator Debug build, and the generic iOS arm64 Release build all succeed. The final source version is `0.8.0 (17)`.
- `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` passes ZIP integrity inspection. Independent checks confirm arm64 host and keyboard binaries, matching `0.8.0 (17)` bundle versions, HID dispatch entitlement only on the keyboard extension, and SHA-256 `462303f384170883e7c89b9b59f234e22b34e06eb87888563ba2fbcda292604d`.
## 2026-09-03 — Task 09

- 已确认 Git 仓库存在且工作区无未提交改动。
- 已读取并采用 `design-md` 与 `planning-with-files` 工作流。
- 已通过 CodeGraph 完成主 App、共享配置与 Keyboard Extension 初始结构勘察。
- 已在 `/Users/mac/backup/2026-09-03_MagicBoard_09/` 备份本轮即将修改的 `DESIGN.md`、`task_plan.md`、`findings.md`、`progress.md`。
- 当前阶段：Phase 7，继续核验平台能力、现有参考实现与中文输入边界。
- 只读参考检索因不存在的 `refrence/iRime*` Zsh 通配符失败；已定位为查询路径错误，未产生项目改动，后续改用明确存在路径。
- `autocli 0.3.8` 已确认可用，但 Google 搜索需使用位置参数；已记录签名差异，后续按本机帮助调用。
- 用户已确认完整离线中文 IME 范围及双拼排序要求；已核实 Apple `UILexicon` 与 Rime 六种标准双拼方案。
- 查询旧 `imfuxiao/LibrimeKit` release 地址返回 404；已确认上游归属迁移，后续改查 `amorphobia/LibrimeKit`。
- 已比较 AOSP PinyinIME 与现代 LibrimeKit：AOSP 更轻但无双拼，LibrimeKit 与官方 Rime 六方案的功能吻合度更高，并能覆盖 arm64 真机/模拟器。
- 已在 `refrence/` 增加 6 个只读研究仓库（AOSP PinyinIME、LibrimeKit、Rime prelude/luna-pinyin/essay/double-pinyin）；总数仍低于 20，并固定提交。
- 已确认 `.tipa` 不自动提供无沙箱权限；系统私有偏好读取需要单独授权决策。
- 用户选择完全私有迁移、精细布局滑杆和混合 Modifier。
- 已查到 `AppleKeyboards` 状态检测与 Apple 动态词库/使用模型路径；GitHub 随后触发 403 限流，已停止搜索并保留已得证据。
- 用户决定先连接实体机再实施私有迁移，因此本阶段不改无沙箱 entitlement；其余功能继续。
- 已将 Task 09 的设置首页、候选栏、六种双拼、精细布局、外观、反馈与 Modifier 规则写入 `DESIGN.md`，`npx @google/design.md lint DESIGN.md` 为 0 findings。
- Phase 8 红灯验证按预期失败：新增设置测试在 `SharedConfig` 尚无 `ldcfg/svcfg` 等 API 时产生编译错误。
- 已实现版本化 `BoardSettings`、七种可选中文方案（全拼 + 六双拼）、布局/外观/反馈/Modifier 配置、旧主题迁移与 `KeyboardReport` 心跳。
- `swift test` 现通过 44/44，覆盖默认值、完整往返、损坏回退、越界归一化、旧主题迁移与扩展状态。
- 主 App 首次重写补丁因同一路径同时 Delete/Add 被工具校验拒绝，文件未变化；后续改用单次更新补丁。
- 共享包 44/44 测试通过；随后一次把 `xcodegen` 留在 Swift Package 子目录执行，因找不到 `project.yml` 安全停止，改回项目根目录后生成成功。
- 已实现标准设置首页：输入法添加跳转、最近运行/完全访问/App Group/引擎状态、全拼与六种双拼、四项精确布局滑块、四种外观与自定义颜色、按键音、扬声器模拟触觉、Sticky Modifier/三种模式、键盘外观预览和真实文本测试区。
- 首次主 App 编译发现 iOS 16 的带 footer `Section` 需使用 header/content/footer 形式；修正两处后通用 iOS 模拟器 Debug 构建成功。
- Keyboard Extension 已在出现和输入上下文变化时读取最新 `BoardSettings`，实时应用高度、横纵间距、外边距、系统/浅色/深色/自定义外观与强调色，并写入最近运行、完全访问和方案状态报告。
- 新增内置扬声器限定的 12ms/72Hz 低频脉冲；外部、耳机或蓝牙输出因路由不满足 `builtInSpeaker` 自动停用，音量随系统输出音量调整。
- Sticky Modifier 首轮 48 项测试有 2 项暴露切换模式不应受 320ms 长按阈值限制；将阈值仅用于混合模式后 48/48 通过，键盘端已接入按住、下一键、双击持续锁定及 HID 释放收敛。
- 已固定 `LibrimeKit@efcb049` 并随扩展打包 Rime 全拼、六种双拼、笔画反查、OpenCC 简体转换和完整第三方许可证；生产启动自检会输入 `nihao` 并要求存在候选。
- 候选栏已接入 `UILexicon`，Rime 候选优先，系统通讯录与文本替换词条按当前输入编码补充。
- 用户指出模拟器输入源应长按地球键直接选择；已停止无效循环点按，并将该路径写入输入测试页。
- 参考 App Store 现有键盘应用 Clink 的预览优先、分类卡片与合并设置结构，主 App 改为常驻双栏：概览、中文输入、外观与布局、按键体验、输入测试。
- 已删除系统习惯迁移、自动补充、等待验证等开发过程文案；概览仅保留四项真实状态与一个设置动作。
- 新版 UI 在 2018 iPad Pro 12.9 模拟器完成目视检查；边栏、状态卡与概览布局显示正确。
- 最终 48/48 测试通过，`DESIGN.md` lint 为 0 findings，模拟器 Debug 与 arm64 Release 均成功。
- 生成 `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`，版本 `0.9.0 (18)`，5,630,399 bytes，SHA-256 `e73cafc7df6283319e9c6403ebd9f6c2811167b3dca97b00fda215f3a7d9c58f`；ZIP、arm64 架构、扩展资源与 entitlement 检查通过。
