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
