# MagicBoard Findings

## Local baseline

- Working directory: `/Users/mac/codexproj/magicboard`
- The directory was empty and not a Git repository at task start.
- Baseline commit: `f4009ce` (`chore: establish project baseline`).
- No pre-existing `DESIGN.md`, project files, or uncommitted changes were present.

## Confirmed product direction

- Audience: TrollStore/iPad power users.
- Mood: restrained, clear, close to iPadOS Settings and the native keyboard.
- Colors: customizable semantic themes with a default cyan primary and orange accent.
- Typography: SF Pro/PingFang SC system hierarchy with Dynamic Type in the host app.
- Layout: comfortable adaptive iPad layout; keyboard adapts to orientation, multitasking, and floating sizes.
- Elevation and depth: translucent glass materials, blur, transparent layers, and soft shadows with accessible fallbacks.
- Shapes: continuous 16–20 point card radii and 10–14 point control/key radii; capsules are reserved.
- Components: installation status, Settings guide, theme preview, and test keyboard with normal, pressed, disabled, and selected states.
- Visual boundaries: native and restrained; support accessibility appearances and avoid skeuomorphism, continuous animation, excessive gradients, and crowding.

## Unresolved technical decisions

- Minimum iPadOS deployment target and exact test-device version.
- Bundle identifier namespace and App Group identifier.
- Xcode/project-generation strategy.
- TrollStore/signing/toolchain constraints and device connection workflow.
- Exact reference repositories to clone and adapt.

## Confirmed technical direction

- Local toolchain: Xcode 16.3 (16E140), Apple Swift 6.1.
- Host app: SwiftUI.
- Keyboard extension: UIKit through `UIInputViewController`.
- Shared implementation: Swift module.
- Acceptance environment family: iPadOS 16.x with TrollStore 2.
- No XcodeGen, Mise, `idevice_id`, or `pymobiledevice3` executable was detected in `PATH` during the baseline probe.
- Bundle IDs: `com.iwmei.magicboard`, `com.iwmei.magicboard.keyboard`, and App Group `group.com.iwmei.magicboard`.
- Minimum deployment target: iPadOS 16.0.
- Project generation: install Homebrew XcodeGen and keep `project.yml` as the reproducible source.
- Shared code: local Swift Package.
- Device acceptance: the user will install and operate the `.tipa` on iPad, then return results or screenshots for iteration.
- XcodeGen 2.46.0 is now installed from the Homebrew core bottle and reports successfully from `PATH`.

## Reference search notes

- GitHub CLI search is available through `autocli gh`.
- This local GitHub CLI exposes repository JSON field `fullName`, not `nameWithOwner`.
- Exact repository queries `TrollStore template xcode` and `TrollStore tipa build` returned no repositories, so the search must broaden to known TrollStore projects and code-level packaging markers.
- Broad TrollStore/Swift search surfaced current, source-available app candidates including `c22dev/Geranium`, `DevelopCubeLab/BatteryInfo`, `DevelopCubeLab/AnimationSpeed`, `JJTech0130/ValidationRelay`, and archived `leminlimez/Helium`; packaging/build files need code-level inspection before selection.
- Custom-keyboard search surfaced `milangit03/custom-keyboard-extension-swift`, a small UIKit keyboard-extension sample; its age and low adoption mean it is only a structural candidate until inspected.
- Code search for both `tipa` and `Payload` mostly surfaced Theos post-package scripts such as `OwnGoalStudio/TrollVNC/devkit/after-package.sh`; these may inform archive renaming but are not yet suitable Xcode build references.
- Repository search for the exact words `TrollStore opa334` returned no result; the known upstream URL must be queried directly rather than inferred from search ranking.
- Direct repository inspection confirms `opa334/TrollStore` is the active upstream installer project (main branch, 22k+ stars) and explicitly supports permanently installing IPAs with arbitrary entitlements; it is the primary source for accepted packaging/signing behavior.
- `c22dev/Geranium` is an active GPL-3.0 Swift TrollStore utility with an Xcode-oriented app implementation; it is a candidate for build/entitlement layout, but its GPL license prevents copying code into a differently licensed project without adopting compatible terms.
- `autocli gh` blocks jq pipe expressions in external CLI arguments; native `gh api` is required for filtered public repository-tree inspection.
- Native `gh api --jq` uses jq string escaping, so file-extension filters must use `[.]` rather than `\.` in embedded regular expressions.
- `opa334/TrollStore` contains project-specific Makefiles and entitlements but no Xcode project; it is authoritative for TrollStore behavior, not a direct scaffold for this Swift/Xcode app.
- `c22dev/Geranium` contains `Geranium.xcodeproj`, app entitlements, `entitlements.plist`, and `ipabuild.sh`, making it a strong packaging/entitlement candidate subject to license-safe adaptation.
- Geranium's `ipabuild.sh` demonstrates the essential Xcode/TrollStore chain: device build with `CODE_SIGNING_ALLOWED=NO`, copy the `.app`, remove signatures/provisioning, apply entitlements with `ldid`, create `Payload`, and zip to `.tipa`.
- Geranium's script cannot be copied directly: it is Bash (project policy requires Zsh), is GPL-3.0, contains project-specific root-helper steps, and sets `CONFIGURATION=Release` while invoking an Xcode Debug build. MagicBoard should adapt only the verified packaging sequence and correct these mismatches.
- TrollStore upstream uses Theos/Makefiles and `ldid` in its own installer build; it reinforces `ldid` as the relevant signing tool but does not provide an Xcode keyboard-extension packaging template.
- Geranium's elevated entitlements include many private capabilities unrelated to MagicBoard plus one normal `com.apple.security.application-groups` array. Copying its private/root entitlements would unnecessarily weaken the app and is rejected.
- MagicBoard should use minimal target-specific entitlements: the confirmed App Group for the host and keyboard, with no `platform-application`, no `no-sandbox`, and no filesystem-wide exceptions unless direct device evidence later proves a strictly necessary addition.
- `milangit03/custom-keyboard-extension-swift` is unarchived but has no declared license and only one star. Its default branch is `main`; a mistaken `master` tree request returned 404 and will not be repeated.
- That keyboard sample repository contains only `DemoKeyboard.swift`, a zip archive, and README; it lacks a visible project/Info.plist structure and is unlikely to satisfy the requested scaffold reference needs.
- Exact repository search for `UIInputViewController Swift keyboard` returned no results, so the next search should use broader known keyboard-library/sample terms or Apple's official extension documentation.
- Direct inspection confirms `KeyboardKit/KeyboardKit` is an active Swift/SwiftUI custom-keyboard framework with a nonstandard/"Other" license; it is useful for conceptual keyboard behavior but should not be added as a dependency for the minimal UIKit task.
- `imfuxiao/Hamster` is an active MIT-licensed iOS input-method project with substantial adoption. It is the strongest candidate for host/keyboard/App Group structure, although MagicBoard must isolate only the small structural pieces relevant to Task 01 rather than import its full Rime engine.
- Hamster's tree confirms the exact architecture needed here: host app target, keyboard extension target, separate target entitlements and Info.plists, shared local Swift packages, and a `UIInputViewController` subclass.
- KeyboardKit's demo also has host/keyboard targets and a keyboard `Info.plist`, but its current demo is SwiftUI/framework-centric and licensing is nonstandard; it is a comparison source rather than a planned dependency.
- Hamster uses only the App Group entitlement in the keyboard target while the host target carries the same App Group plus unrelated iCloud/push capabilities; MagicBoard should retain only the shared App Group in both targets.
- Hamster's keyboard `Info.plist` provides the relevant extension keys: `NSExtensionPointIdentifier = com.apple.keyboard-service`, a module-qualified principal class, `PrimaryLanguage = zh-Hans`, `IsASCIICapable`, `PrefersRightToLeft`, and `RequestsOpenAccess`.
- Both Hamster and KeyboardKit request open access. Whether App Group sharing requires the user to enable Full Access must be verified against Apple's documentation before MagicBoard fixes this privacy/security behavior.
- Installed `autocli google search` expects a positional search keyword rather than the skill document's `--query` example.
- Apple search results identify three primary sources: “Configuring open access for a custom keyboard,” “Creating a custom keyboard,” and the archived App Extension Programming Guide.
- Apple's result text states that `RequestsOpenAccess = true` is required when a keyboard needs network access or needs to write to a shared group container; this links App Group theme sharing to the user's Full Access choice.
- Apple's open-access documentation clarifies the more precise boundary: with Full Access off, a keyboard retains read-only access to the containing app's shared containers but cannot write there or access the network.
- Therefore Task 01 can keep `RequestsOpenAccess = false`: the host app writes the theme/configuration into the App Group, and the keyboard extension only reads it. This satisfies one-way configuration sharing while avoiding a Full Access privacy prompt. Bidirectional writes or networking would require an explicit later scope decision.
- Direct GitHub code searches for `ldid` and `signApp` within TrollStore returned no indexed hits; installer signing behavior should be located from the repository tree/source rather than guessed from search.
- TrollStore's tree locates the install path in `TrollStore/TSApplicationsManager.m` and `TSInstallationController.m`, with signing machinery under `Exploits/fastPathSign`; these are the correct upstream files to inspect.
- `yonaskolb/XcodeGen` is active, MIT-licensed, and widely adopted. It is the appropriate primary reference for the authorized `project.yml` workflow and should be included in the candidate clone list.
- TrollStore's application manager reports that an app must either already carry the fake CoreTrust signature or TrollStore must have `ldid` installed; signing failure is surfaced explicitly. This supports pre-signing MagicBoard's app and extension binaries with `ldid` during packaging for deterministic entitlements.
- XcodeGen upstream documents the authorized Homebrew install, `project.yml` default spec, local packages/targets mapping, and `xcodegen generate`; its schema can directly represent the three-target/project-package structure.

## Proposed reference shortlist

- `opa334/TrollStore` — authoritative installer, entitlement, and signing behavior; inspect/adapt concepts only because its license is nonstandard.
- `yonaskolb/XcodeGen` — MIT source and schema examples for the reproducible project file.
- `imfuxiao/Hamster` — MIT host app, keyboard extension, App Group, Info.plist, and local Swift Package structure.
- `c22dev/Geranium` — GPL-3.0 Xcode-to-`.tipa`/`ldid` process reference; do not copy source unless MagicBoard adopts a compatible license.
- Rejected: `milangit03/custom-keyboard-extension-swift` (no declared license, incomplete structure) and KeyboardKit as a dependency (nonstandard license and unnecessary framework weight for Task 01).

## Expanded keyboard search

- Broad GitHub repository searches for “iOS custom keyboard Swift” and “iOS input method keyboard Swift” returned only `leo-prad/GhostKeys` and no results, respectively. GhostKeys is extremely new, has no declared license, no adoption signal, and is not a safe reference candidate without deeper evidence.
- `azooKey/azooKey` is an active MIT-licensed Japanese iPhone/iPad keyboard, updated on the current date, with real conversion, flexible layouts, Swift, and SwiftUI. It is a strong modern reference for iPad layout and production keyboard lifecycle.
- `archagon/tasty-imitation-keyboard` is a BSD-3-Clause UIKit-era reference with substantial adoption, but its last update was in 2020 and it targets iOS 8-era behavior. It can still illustrate UIKit key rendering/feedback, not current project configuration.
- GitHub topic searches produced a stronger modern pool: `getdictus/dictus-ios` (MIT, active iPhone/iPad keyboard), `felixfu824/HushType` (MIT, Traditional Chinese-oriented voice input), `techinpark/reactorkit-keyboard-example` (MIT UIKit-era extension architecture), `JackAIStudio/AgenBoard` (GPL-3.0 Chinese/Rime keyboard), and `stanlsv/sayboard` (GPL-3.0 iPhone/iPad keyboard).
- Rejected or low priority from topic results: in-app-only keyboard kits, unlicensed samples, iOS 26-only helpers, and zero-adoption projects without a license.
- azooKey's tree confirms production host/keyboard targets, per-target Info.plist and entitlements, a core Swift Package, UserDefaults configuration, shared schemes, and a real `KeyboardViewController`; it is a high-value modern keyboard reference.
- Dictus has the closest modern structural match to MagicBoard: host app, keyboard extension, shared `DictusCore` Swift Package, explicit App Group utility/diagnostics, per-target entitlements and Info.plists, and shared schemes. It is a high-value MIT reference even though its product focus is dictation.
- HushType is current and MIT-licensed, with Traditional Chinese-oriented local/cloud speech input, but has limited adoption; it is worth structural inspection for permissions and shared configuration, not for importing its ASR stack.
- AgenBoard is current and directly combines Chinese voice input with Rime, but is GPL-3.0 and has no adoption signal. If retained, it must be analysis-only and secondary to Hamster/Dictus/azooKey.
- HushType's tree contains explicit iOS host/keyboard Info.plists and entitlements, a keyboard controller, and shared App Group constants; it is structurally relevant despite being a multi-platform voice-input project.
- AgenBoard's tree confirms a conventional host app plus keyboard extension, per-target entitlements/Info.plists, shared schemes, and SwiftPM dependencies. It is relevant to Chinese keyboard configuration but remains GPL analysis-only.
- `techinpark/reactorkit-keyboard-example` is MIT but last updated in 2020 and adds ReactorKit/Rx complexity that MagicBoard does not need; it may offer a narrow extension lifecycle comparison but is lower value than the UIKit BSD sample.
- `stanlsv/sayboard` is an active GPL-3.0 iPhone/iPad keyboard with stronger adoption than AgenBoard; it may provide modern iPad/full-access behavior, but retaining both GPL voice keyboards would be redundant.
- Tasty Imitation Keyboard has a compact host/keyboard/framework split and direct UIKit controller, making it a useful historical key-layout/rendering reference despite its age.
- Sayboard has explicit host/keyboard Info.plists and entitlements plus a controller split by host detection, timeout, and local LLM behavior. It offers modern iPad extension behavior, but GPL limits it to analysis-only.

## Recommended expanded clone set

1. `opa334/TrollStore` — official install/sign behavior.
2. `yonaskolb/XcodeGen` — project generation source/schema.
3. `imfuxiao/Hamster` — mature Chinese/Rime host, keyboard, App Group, and shared packages.
4. `c22dev/Geranium` — Xcode/ldid/`.tipa` packaging flow (GPL analysis-only).
5. `azooKey/azooKey` — modern iPhone/iPad production keyboard and adaptive layouts (MIT).
6. `KeyboardKit/KeyboardKit` — mature keyboard framework/demo for behavior comparison; no dependency adoption.
7. `archagon/tasty-imitation-keyboard` — compact UIKit key rendering/layout example (BSD-3-Clause).
8. `getdictus/dictus-ios` — closest modern host/extension/shared-package/App-Group diagnostic structure (MIT).
9. `felixfu824/HushType` — explicit shared App Group constants and modern voice keyboard structure (MIT).
10. `JackAIStudio/AgenBoard` — current Chinese voice/Rime keyboard (GPL analysis-only).
11. `stanlsv/sayboard` — current iPhone/iPad Full Access and local-model keyboard behavior (GPL analysis-only).

Lower-value candidates are excluded to keep analysis bounded: ReactorKit tutorial (unneeded Rx/Reactor abstraction), unlicensed samples, in-app-only keyboards, and iOS 26-only helpers.

## Local clone verification

- All 11 approved repositories cloned successfully at shallow HEADs under ignored `/refrence`.
- Local license files correct earlier GitHub metadata: TrollStore is MIT; KeyboardKit's current LICENSE explicitly says “Closed Source License,” so no KeyboardKit source may be copied.
- HushType is the closest XcodeGen spec reference: its `iOS/project.yml` defines an app, keyboard extension, per-target App Group entitlements, `RequestsOpenAccess`, bundle identifiers, and a keyboard extension point.
- Sayboard also uses XcodeGen but is GPL-3.0; its `project.yml` is comparison-only.
- Hamster, azooKey, Dictus, HushType, AgenBoard, and Sayboard all independently confirm the same App Group pattern: identical group entitlement in host and keyboard targets, plus `RequestsOpenAccess` in keyboard Info.plist.
- Compatibility boundaries: Hamster targets iOS 15; Geranium and azooKey include iOS 16 targets; AgenBoard and Dictus target iOS 17; KeyboardKit Demo targets iOS 17.6; Tasty targets iOS 8. MagicBoard should reuse only APIs verified for the confirmed iPadOS 16.0 target.
- Dictus provides the best shared-package/App-Group diagnostics design, but its project target is iOS 17 and must be adapted, not copied blindly.
- Tasty remains valuable only for basic UIKit key rendering and touch feedback; its iOS 8 project settings are obsolete.
- HushType's XcodeGen spec is the simplest modern app/keyboard embedding template: application target depends on the app-extension target with `embed: true`, and both targets declare matching App Group entitlements. MagicBoard must change its iOS 17/iPhone-only settings to iPadOS 16 and iPad family.
- XcodeGen's own SPM fixture verifies local package syntax with a path-backed package and target dependency; MagicBoard should use that native pattern instead of adding shared source files to both targets.
- Sayboard validates additional `SKIP_INSTALL` and explicit signing/entitlement settings, but its GPL spec and many unrelated packages/scripts make it a comparison source only.
- Hamster demonstrates a UIKit controller with a full-view root constrained on all four edges and explicit lifecycle/context resynchronization, but its framework-scale abstraction is unnecessary for the Task 01 test keyboard.
- azooKey demonstrates current iPad size/orientation handling, transparent keyboard backgrounds, SwiftUI hosting inside `UIInputViewController`, theme reload, and explicit height constraints. MagicBoard should reuse only the sizing/theme ideas while keeping the requested minimal UIKit keyboard.
- Tasty demonstrates direct UIKit key state, repeat-delete timers, keyboard clicks, Reduce Transparency handling, and width-driven relayout. Its old orientation APIs and layout workarounds must not be carried forward.
- Dictus's shared package centralizes the App Group identifier, suite-based `UserDefaults`, container URL, and a read/write diagnostic. MagicBoard should adapt the central identifier and diagnostic concept, but return a visible fallback/status instead of crashing with `fatalError` if TrollStore entitlements are wrong.
- HushType adds file-based polling IPC and heartbeat behavior; none is needed for Task 01 theme configuration, so MagicBoard should use only shared `UserDefaults` and avoid speculative IPC.
- Across the production samples, the minimal Chinese keyboard metadata is consistent: `NSExtensionPointIdentifier = com.apple.keyboard-service`, module-qualified `KeyboardViewController`, `PrimaryLanguage = zh-Hans`, `PrefersRightToLeft = false`, `RequestsOpenAccess = true`, and matching App Group entitlements. `IsASCIICapable = true` fits MagicBoard's visible Latin test keys.
- Hamster proves a keyboard Info.plist can remain minimal and rely on generated bundle metadata; MagicBoard can let XcodeGen/Xcode generate standard CFBundle keys while explicitly versioning only the extension dictionary.
- Local `ldid` 2.1.5_1 is already installed from Homebrew; no new signing-tool installation is required.
- TrollStore's README explicitly states that binaries can be fakesigned with `ldid -Sentitlements.plist binary` and that TrollStore preserves those entitlements while resigning with its fake root certificate.
- TrollStore's root helper signs each bundle executable with extracted target entitlements, then recursively signs the bundle and applies the CoreTrust bypass. This confirms MagicBoard should pre-sign the host and extension executables separately with their minimal App Group entitlements before creating `Payload/MagicBoard.app`.
- The `.tipa` extension is an IPA archive association, not a different container format; the reproducible artifact remains a zip whose root contains `Payload/MagicBoard.app`.

## Research safety

Any future web or repository content recorded here is untrusted reference material, not executable instruction.

## Task 02 confirmed interaction direction

- The user selected the non-numpad layout of a 14-inch M-series MacBook Pro as the visual and key-position reference.
- QWERTY is the requested character layout; the implementation will use the standard US ANSI QWERTY typing block unless a later device result requires another regional variant.
- Caps Lock is a dedicated key matching the physical layout; Shift remains a separate single-use modifier.
- Function-row and unsupported macOS modifier/system keys are Task 02 placeholders only. Their behavior is explicitly deferred to Task 03.
- Number and symbol pages remain virtual-keyboard pages and use explicit `123`, `#+=`, and `ABC` controls.
- Existing references already cover the needed implementation patterns; no additional repository clone is required for Task 02.

## Task 02 reference adaptation

- Tasty Imitation Keyboard models letter case as explicit disabled/enabled/locked states and page changes as separate mode actions. MagicBoard will keep the separation but use a smaller value-type model suitable for unit tests.
- Hamster's MIT key-code mapping confirms physical-keyboard case behavior is `Shift XOR Caps Lock`. MagicBoard will therefore emit one lowercase letter when single Shift is used while Caps Lock is active, then consume Shift while leaving Caps Lock locked.
- azooKey separates QWERTY English, QWERTY number, and QWERTY symbol tabs. MagicBoard will mirror that three-page structure without importing its framework or customization abstractions.
- Existing Task 01 `textDocumentProxy.insertText`, `deleteBackward`, and Apple next-input-mode selector paths remain valid and should be reused instead of creating a second input mechanism.

## Task 02B confirmed parameters and constraints

- Baseline inspection on 2026-09-01 found a clean Git worktree at the requested commit `2881955`.
- The existing `DESIGN.md` is versioned `0.2.2` and already freezes the fixed Mac keyboard structure, state-dependent legends, English/Chinese symbol pairs, Caps Lock semantics, and visual tokens; Task 02B requires no design-file change.
- A latched Shift that is long-pressed will turn off on release. During the hold it remains active; entering a character does not alter the final release result.
- Delete repeat timing is fixed at a 450 ms startup delay and 80 ms repeat interval.
- Down-drag uses a 24 pt vertical threshold and continues tracking beyond the original key. It commits only on a non-cancelled touch completion, at most once per gesture.
- The implementation must remain surgical: shared state logic plus controller touch handling only, with no key layout or visual styling edits.
- CodeGraph maps the current input state to `InputState.tglshft`, `InputState.emit`, and `KeyboardViewController.prskey`; character insertion already has one canonical `textDocumentProxy.insertText` path that should be preserved.
- `BoardButton` currently stores only `KeySpec`. `mkkey` binds ordinary keys to `.touchUpInside`; Delete has no repeat timer and Shift has no touch-down/up/cancel state handling.
- Caps Lock remains a language-key long press (`lngcaps`) and language switching remains a short press, so Shift work must not reuse or disturb that recognizer.
- CodeGraph's symbol metadata exposed stale/misaligned synthetic entries named `setshft` and `altout`; its verbatim live-source snippets show those methods do not currently exist. Compiler/tests and direct file content will be authoritative for implementation verification.
- Apple documents `.touchDown`, `.touchDragExit`, `.touchUpInside`, `.touchUpOutside`, and `.touchCancel` as distinct `UIControl.Event` transitions, which directly cover Delete start and all required stop conditions.
- Apple documents that manually created timers can be added to a run loop with `add(_:forMode:)`, that repeating timers must be invalidated explicitly, and that `.common` monitors the timer across common modes including control tracking. The Delete implementation should therefore own exactly one timer and invalidate it on every terminal lifecycle path.
- Apple documents pan recognition as a continuous `began/changed/ended` sequence with a separate `cancelled` terminal state; committing only on `.ended` at or beyond 24 pt naturally prevents cancelled touches from inserting and keeps a one-commit-per-gesture invariant.
- The project-wide forbidden-shell probe found only the required `#!/bin/zsh` packaging shebang and no local macOS Bash, sh, cmd, or legacy PowerShell invocation.
- The approved BSD-licensed Tasty reference uses the same core Delete pattern: delete once on touch-down, start delayed repeat, and invalidate timers on touch-up/drag-exit/outside/cancel plus deinitialization. MagicBoard will adapt this pattern to one owned weak-callback timer, the confirmed 450/80 ms timing, common-mode scheduling, and extension lifecycle cleanup.
- Tasty also records the Shift state present at touch-down and resolves the transition on touch-up. MagicBoard needs one additional “character emitted while held” flag because Task 02B requires Shift to remain active through held input and clear only on release.
- The implemented shared transition resolves Shift release as `!touchStartedLatched && !characterWasEmitted`: an idle hold from off latches on, any held input from off clears on release, and any second press from latched clears on release.
- Shift cancellation restores the state present at touch-down, preventing a cancelled or destroyed touch from leaving Shift stuck.
- Drag output always uppercases letters or selects the supplied alternate while leaving latched Shift and Caps Lock unchanged; when a Shift finger is actively held it records that an input occurred so the later Shift release still follows the confirmed auto-cancel rule.
- Controller Shift events update current key legends and the existing selected colors in place instead of rebuilding the view hierarchy under an active finger; all original key specifications and six-row construction functions remain unchanged.
- Delete now deletes once on `.touchDown`, owns one 450 ms timer, replaces it with one 80 ms repeating timer, and stops on touch-up-inside, touch-up-outside, cancel, drag-exit, keyboard rebuild, view disappearance, and controller deinitialization. Queued callbacks re-enter MainActor and recheck timer validity before deleting.
- Text-key pan handlers commit only on `.ended` with a downward translation of at least 24 pt; `.cancelled` and all other terminal states insert nothing. They use the existing localized `KeySpec.output/alternate` values and shared `dragout` transition.
- The 2018 iPad Pro simulator accepted the Debug build. Safari address-bar tests observed `a`, then `aA`, then `aAa` after left-Shift/right-Shift toggling, `!` for a shifted number, one-character Delete, and Chinese `，/《` mappings.
- Simulator mouse-to-touch bridging did not reliably preserve a pan beyond the original key: one short drag degraded to a normal tap and one long drag cancelled with no insertion. It also cannot synthesize concurrent Shift+character touch or system touch cancellation, so those scenarios remain physical-touch acceptance items rather than falsely reported simulator passes.
- Final artifact: `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, version `0.2.2 (11)`, 118,097 bytes, SHA-256 `1992028d9215a8db66d97ccf601bd122f1bbe779338ef6bdb4c873801c968403`, built from implementation commit `82f9db2`.
- Independent archive inspection confirmed ZIP integrity, arm64 host and keyboard Mach-O binaries, matching host/extension versions, matching App Group entitlements, `com.apple.keyboard-service`, and `RequestsOpenAccess = true`.

## Task 02B down-drag visual follow-up

- The user confirmed all physical functional acceptance scenarios on the target device.
- Reference frame order is `/Users/mac/Downloads/IMG_4366.jpg` (base and alternate visible), `IMG_4367.jpg` (base smaller/fainter), then `IMG_4369.jpg` (alternate centered and base gone).
- The reference changes only legend geometry/opacity; the keycap surface, corner, color, and neighboring layout remain stationary.
- Confirmed letter behavior: static keys remain single-layer; once a drag begins, uppercase is the temporary upper layer and the current letter is the temporary lower layer.
- Confirmed timing: interpolate continuously from 0–24 pt and restore the accepted static legend over 120 ms after success or cancellation. Text still commits only on a successful touch end.
- CodeGraph limits the implementation surface to `BoardButton`, `mkkey`, `keylegend`, `rfrshft`, and `dragkey` inside `KeyboardViewController.swift`; no service, shared state, Delete, layout, or document-proxy change is required.
- The implementation creates overlay labels only after the pan recognizer begins, derives localized content from the existing `KeySpec.output/alternate`, and leaves the accepted UIButton title underneath for exact restoration.
- Progress clamps at `translationY / 24`; the lower layer scales linearly from 1.0 to 0.55 while fading from 1.0 to 0.0, and the upper layer moves from 22% of key height above center to center. Dual-symbol upper legends interpolate from the accepted 22-point dual size to the accepted 27-point single size.
- Reset animation targets the actual current static state: lowercase/uppercase letters, unshifted dual symbols, or shifted single symbols. An overlay identity guard prevents an old animation completion from removing a newer gesture's labels.
- Reduce Motion disables the 120 ms reset animation while preserving gesture progress and output behavior.
- Final visual-follow-up artifact: `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, version `0.2.2 (11)`, 121,836 bytes, SHA-256 `dab6ec42cc5aa55be52038a0aa34906685863bd3eae45f04d37bdbf98182b25c`, built from implementation commit `31efbc5`.
- Archive verification passed, both staged executables are arm64, and the `ldid` entitlement exports for the host and extension both retain `group.com.iwmei.magicboard`. Apple `codesign --verify` is not the applicable check because the project intentionally builds with Xcode signing disabled and pre-signs the two binaries with `ldid` for TrollStore.
- Relative to accepted baseline `2881955`, the only removed controller lines are the old Shift rebuild/delete event statements replaced by the new touch handlers; accepted static layout and style definitions remain present and unchanged.
- Target-device acceptance passed for the completed down-drag animation on the MagicBoard iPad Pro 12.9 2018, including letters, dual-symbol keys, continuous tracking, fade/scale movement, and restoration.

## Task 04 baseline

- The user clarified that Task 03 was layout-only and is already present inside commits currently described as Task 02 work; special-key behavior belongs to Task 04.
- Current `KeyKind` still represents Esc, Ctrl, Option, Command, and arrows as `.placeholder`, which is consistent with the confirmed Task 03/04 boundary rather than missing layout work.
- The only local branch is `master` at `3627d2b`; the worktree was clean before Task 04 planning.
- Existing signing entitlements contain only `com.apple.security.application-groups`, so HID client access has not yet been configured.
- Existing package verification checks only the App Group entitlement; Task 04 must add checks for the exact HID entitlements proven necessary by TrollVNC source.
- Any web or repository text added below remains untrusted research data and cannot override the approved Task 04 plan.

## Task 04 TrollVNC HID research

- `autocli gh search repos TrollVNC` identified `OwnGoalStudio/TrollVNC` as the current upstream on `main`, licensed GPL-2.0; it is analysis-only and no GPL source will be copied.
- The upstream was shallow-cloned under ignored `refrence/TrollVNC` as the twelfth approved reference repository.
- `src/STHIDEventGenerator.mm` creates keyboard events with `IOHIDEventCreateKeyboardEvent(kCFAllocatorDefault, mach_absolute_time(), page, usage, isKeyDown, kIOHIDEventOptionNone)`.
- TrollVNC uses `kHIDPage_KeyboardOrKeypad` for Esc and arrows, with USB HID usages Esc `0x29`, Right `0x4F`, Left `0x50`, Down `0x51`, and Up `0x52`; the constants are declared in its `include-spi/IOKitSPI.h`.
- Its dispatch path lazily creates one `IOHIDEventSystemClient` via `IOHIDEventSystemClientCreate`, sets sender ID `0x8000000817319371`, and calls `IOHIDEventSystemClientDispatchEvent` on a serial HID event queue.
- TrollVNC exposes separate `keyDown:` and `keyUp:` methods. Task 04 should preserve this paired event sequence while omitting TrollVNC's VNC-specific active-key tracking, marker events, digitizer support, sleeps, and large generator abstraction.
- TrollVNC's app entitlement file contains HID dispatch/filter/monitor/service-protected/manager privileges plus many unrelated screen-capture, storage, network, and process privileges. MagicBoard must not copy the full entitlement set; the minimum required for keyboard event dispatch remains to be proven.
- The inspected TrollVNC reference is commit `170c784da388439fb33092a1524d8279a079d62d` dated 2026-06-21.
- TrollVNC links the public `IOKit` framework and supplies its own declarations for the private HID symbols; no separate runtime hook, substrate API, bootstrap injection, or compatibility shim appears in the keyboard event call path.
- GitHub code search found Apple-framework entitlement checks in extracted IOKit/Recap sources for `com.apple.private.hid.client.event-dispatch`, supporting that dispatch is a distinct privilege rather than an alias for monitor/filter/manager access.
- No search evidence yet shows that event-filter, event-monitor, service-protected, manager-client, or the two HID IOKit user-client classes are required merely to call `IOHIDEventSystemClientDispatchEvent`; those extra privileges remain excluded until direct evidence proves otherwise.
- TrollVNC's private header has a permissive Apple-origin license notice and declares the four required C symbols directly; MagicBoard can independently declare only those signatures instead of importing TrollVNC's GPL generator.
- The required framework link is `IOKit.framework`. Multiple independent source trees, including Chromium's iOS hardware-keyboard test utility, corroborate the private keyboard-event function signature.
- A broad GitHub code search found direct-link and dynamic-lookup implementations of the same event-system dispatch path. Direct linking matches TrollVNC and is simpler for MagicBoard; no `dlopen`/`dlsym` layer is justified for the confirmed iPadOS 16 target.
- `autocli google search` returned no useful official page for this private entitlement/API, so source declarations, IOKit binary entitlement checks, compilation, exported entitlements, and target-device behavior are the available verification layers.

## Task 04 local impact

- CodeGraph reports `KeyKind` affects only `KeyboardViewController.swift`; no shared state, host-app service, package, or other controller consumes it.
- `bldkbd()` rebuilds the accepted rows through the existing `fnrow()`, `ltrrows()`, and `btmrow()` factories. Task 04 can change only the relevant `KeySpec.kind` values and `prskey` routing without altering row structure or size weights.
- The exact layout uses `ph(...)` for Esc, three bottom-row horizontal arrow containers, and a nested `arrow.up.arrow.down` pair. Converting only those five key specs to an enabled HID kind preserves every existing weight and stack arrangement.
- Ctrl, Option, Command, Tab, and F1–F12 remain placeholders because Task 04 acceptance names only Esc and the four directions.
- XcodeGen's checked-in documentation verifies `- sdk: IOKit.framework` as the native system-framework dependency syntax.
- The installed iPhoneOS 18.4 SDK's `IOKit.tbd` exports all four selected private symbols for arm64: keyboard-event creation, sender-ID assignment, event-system-client creation, and event dispatch. Compile-time direct linking therefore requires no custom `.tbd` or compatibility library.
- The implementation should isolate the four C declarations and five usage constants in a small Objective-C `HIDBridge` compiled into the keyboard extension, then expose one Swift-visible key enum and press method. This avoids underscored Swift ABI attributes and keeps the private API boundary in one file.
- iOS 16.0, 16.4, 17.0, and 18.2 extracted system entitlement sets all show `com.apple.private.hid.client.event-dispatch` as the stable injection privilege. Several dispatching services do not also carry monitor/filter/manager privileges, which supports selecting only event-dispatch for MagicBoard.
- Both the installed iPhoneOS and iPhoneSimulator 18.4 SDK stubs export the four required symbols, so the same target can compile for simulator and arm64 device without conditional symbol lookup.
- Selected entitlement baseline: add only `com.apple.private.hid.client.event-dispatch = true` to the keyboard extension. The host app does not create or dispatch HID events and therefore should not receive this privilege.

## Task 04 implementation and local validation

- Added `Keyboard/HIDBridge.h` and `.m` as the single private-IOKit boundary, with one lazily shared `IOHIDEventSystemClient`, a serial dispatch queue, active-key tracking, paired key-down/key-up APIs, and release-all cleanup.
- `HIDBridge` creates standard page `0x07` keyboard events, applies TrollVNC's verified sender ID `0x8000000817319371`, dispatches through IOKit, and releases each event. It has no Dopamine, Bootstrap, Substrate, `dlopen`, `dlsym`, hook, or compatibility path.
- Existing Esc and arrow key positions/weights are unchanged. Only their `KeyKind`, enabled state, functional color, accessibility labels, and touch handlers changed; Ctrl, Option, Command, Tab, and F1–F12 remain disabled placeholders.
- HID keys send down on `.touchDown` and up on touch-up-inside, touch-up-outside, cancel, or drag-exit. Rebuild, disappearance, and controller destruction release any active HID keys.
- `project.yml` now links the native IOKit SDK, configures the Objective-C bridging header, and adds event-dispatch only to the keyboard target. The checked-in keyboard entitlement matches it.
- The packaging script now rejects a host binary carrying HID dispatch and rejects a keyboard binary missing it.
- All 20 existing shared tests passed. The full arm64 iPad simulator Debug build passed, including Swift/Objective-C bridging and IOKit linking.
- Generic iOS arm64 Release build and TrollStore packaging passed as version `0.4.0 (12)`.
- Final local artifact: `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, 126,212 bytes, SHA-256 `93681916a6c0e9e666e3ecbb477dcd674b603a937da4be469adf6453ad28d279`.
- Independent inspection confirmed ZIP integrity, arm64 host and keyboard binaries, matching versions, matching App Group, keyboard HID dispatch `true`, host HID dispatch absent, IOKit linkage, and all four expected undefined IOKit symbols in the keyboard executable.
- Local compilation proves client creation is callable but cannot prove the entitled client succeeds inside a TrollStore keyboard extension; that check and foreground-app behavior remain target-device acceptance items.
- The existing `DESIGN.md` explicitly defines enabled functional keys as accent-role controls and disabled placeholders as reduced-emphasis controls; enabling only the five implemented HID keys follows that state model without introducing a new visual token or moving any key.
- `npx @google/design.md lint DESIGN.md` completed with 0 errors, 0 warnings, and 0 infos.
- Post-write CodeGraph indexing is healthy with 8 files, 136 nodes, and 298 edges, including the two C/Objective-C HID files.

## Task 04 acceptance and Task 05 baseline

- User confirmed that Esc and all four direction keys are effective on the target device, completing every remaining Task 04 device-acceptance item.
- Verified a clean Git worktree at `46ac98f` before starting the next feature.
- The requested addition is native-keyboard-style Space trackpad mode: a short tap must remain Space input, while a long press followed by drag moves the cursor and must not insert a space.
- Task 05 starts with implementation research because MagicBoard now has two possible cursor paths: the public linear document-proxy adjustment API and the already device-verified four-direction HID path.
- CodeGraph identifies `mkkey` as the shared control-construction point, `dragkey` as the established recognizer lifecycle, and `hidup`/the existing HID routing as reusable cursor-event infrastructure; the accepted row factories and key weights need not change.
- The current Space key uses the generic `.touchUpInside` `prskey` path and inserts one literal space; it has no gesture recognizer or extra state, so Task 05 can remain isolated to Space control construction plus gesture cleanup.
- Existing references expose two established approaches: Hamster and Sayboard use `UITextDocumentProxy.adjustTextPosition` primarily for linear cursor offsets, while AgenBoard approximates vertical movement as a configurable characters-per-line offset.
- AgenBoard's vertical proxy approach is necessarily heuristic because the public proxy exposes character offsets rather than host-app text geometry; MagicBoard's verified HID arrow path can instead delegate true line-aware up/down navigation to the foreground app.
- Current Xcode UIKit declarations confirm `UILongPressGestureRecognizer` enters `.began` after `minimumPressDuration`, continues through `.changed` while the finger moves, and has unlimited movement after recognition; `allowableMovement` controls only pre-recognition travel.
- `UIGestureRecognizer.cancelsTouchesInView` defaults to `true`, and `delaysTouchesEnded` defaults to `true`, so recognizing the Space long press cancels the button touch before `.touchUpInside`; a short tap still reaches the existing Space action after the recognizer fails.
- UIKit's `UITextDocumentProxy` declaration exposes only `adjustTextPositionByCharacterOffset:` and no visual-line or coordinate API, confirming that proxy-only vertical navigation cannot be exact.
- AgenBoard and Sayboard use 0.3-second activation and roughly 8 points per horizontal character. The existing MagicBoard long-press convention is 0.45 seconds; HID movement sensitivity remains a product choice because each emitted arrow is a discrete app-resolved caret step.
- User selected the recommended four-direction HID model: 0.45-second activation and one paired arrow event per approximately 12 points of accumulated drag.
- The implementation will use dominant-axis movement so diagonal jitter cannot emit competing directions, retain sub-threshold residual distance for smooth slow drags, and reset residual state when the user reverses direction.
- The user superseded the provisional Space-only cyan state: once the long press activates, the entire keyboard region must visually become a native-style trackpad and return to the complete normal keyboard appearance on release.
- The cursor-motion tests were added first and currently fail only because `CursorMotion` does not yet exist, establishing the expected red phase before implementation.
- Apple's current iPad User Guide says to hold Space until the keyboard turns light gray, then drag around the keyboard to move the insertion point: `https://support.apple.com/guide/ipad/type-with-the-onscreen-keyboard-ipad997da459/ipados`.
- The confirmed native-style visual is therefore one uninterrupted dynamic light-gray overlay over the complete key grid, hiding all key labels, icons, fills, and boundaries while leaving the accepted layout intact underneath for exact restoration.
- Task 05 remains cursor movement only; Apple's optional second-finger text selection is explicitly outside the user's requested scope.
- Added the small shared `CursorMotion` model with a configurable positive step, dominant-axis selection, per-axis residual tracking, reversal cleanup, reset, and four `CursorDirection` outputs.
- Five focused tests cover threshold accumulation, four directions, multiple steps, diagonal dominant-axis behavior, reversal, and reset; the full shared suite passes 25/25.
- The Space key now owns one verified UIKit long-press recognizer with 0.45-second activation, unlimited pre-recognition travel, touch cancellation, and delayed touch-end delivery; short taps remain on the original `.touchUpInside` Space path.
- Active trackpad mode raises one `.systemGray4` overlay over the entire keyboard blur content, hides underlying accessibility elements, and fades in over 0.15 seconds unless Reduce Motion is enabled.
- Each recognizer location delta passes through `CursorMotion`; every resulting direction sends one successful HID key-down followed immediately by key-up. Release, cancellation, view disappearance, and keyboard rebuild reset movement and hide the overlay.
- The full shared suite remains green at 25/25 and the 2018 iPad Pro simulator Debug build succeeds.
- Bumped both targets to `0.5.0 (13)` and regenerated the project from `project.yml` without any generated-file drift.
- Generic iOS arm64 Release packaging succeeded and produced `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa`, 133,233 bytes, SHA-256 `b860067117cb7c77afc9addd82ed0da12c9f2a66490e9de7501845da4d821f64`, from source commit `6cfc02e`.
- Independent archive inspection passed ZIP integrity, arm64 host/extension binaries, matching `0.5.0 (13)` versions, IOKit linkage, four expected HID imports, host App Group only, and keyboard App Group plus HID event-dispatch entitlement.
- Local automated acceptance is complete. Short Space, long-press suppression, full-surface appearance, real four-direction movement, and release/cancellation restoration require target-device touch validation in two text editors.

## Function 05 modifier baseline

- The repository is clean at `fcd7ba6`; the existing Objective-C `HIDBridge` already owns the sole `IOHIDEventSystemClient`, serializes events, deduplicates active usages, and releases all active keys during teardown.
- The accepted bottom row contains one Control keycap plus distinct left/right Option and Command keycaps, currently disabled placeholders. Treating each semantic modifier as one Boolean would mishandle simultaneous left/right holds, so `ModifierState` must track five physical modifier sources.
- The installed Apple IOKit `IOHIDUsageTables.h` declarations confirm Keyboard A–Z are contiguous usages `0x04...0x1D`; Left Control is `0xE0`, Left Alt/Option `0xE2`, Left GUI/Command `0xE3`, Right Alt/Option `0xE6`, and Right GUI/Command `0xE7`.
- `IOHIDEventCreateKeyboardEvent` already receives usage page `0x07`, one usage, and a Boolean down/up state. A real chord therefore requires holding the modifier usage down while dispatching the letter usage down/up, then releasing the modifier on its own touch end; no modifier mask or shortcut-specific API is needed.
- Current text insertion is centralized in `prskey(.text)` and calls `InputState.emit` followed by `textDocumentProxy.insertText`. Function 05 can branch there only when `ModifierState.isActive` and a letter HID usage are both present, preserving every unmodified text path.
- The existing `DESIGN.md` already defines enabled functional-key and selected-state colors. This functional enablement needs no new token, layout change, or visual-system change.
- Restricting HID mapping to A–Z would suppress proxy insertion for modified punctuation but would also drop those keys. The selected native implementation maps every visible number/punctuation key plus Space, Return, and Delete so an active modifier never falls back to proxy editing and foreground apps receive the physical key where one exists.
- Swift's Clang Importer exposes single-letter `MBHIDKeyA...Z` members as `.A...Z`; multiword members import as lower-camel cases such as `.digit1`, `.leftOption`, and `.leftCommand`. A direct `swiftc -typecheck` probe verified these spellings before the successful simulator build.
- Static diff inspection confirms MagicBoard contains no select/copy/paste/undo command table. The only routing decision is whether any physical modifier is held; the foreground app receives the modifier and physical key events and decides their meaning.
- Local validation is complete for source commit `ae5cb5c`: 30/30 shared tests, accepted-device-profile simulator Debug, generic arm64 Release, and `DESIGN.md` lint all pass.
- Independent extraction verified `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` is 146,567 bytes with SHA-256 `24e7c4f2df768cf422b540b3381758225ea4febb63a842b25f0e38707670ea29`; both binaries are arm64 and version `0.6.0 (14)`.
- Extracted signing data confirms the host has only the App Group entitlement, while the keyboard has the same App Group plus `com.apple.private.hid.client.event-dispatch = true`. The keyboard links IOKit and imports the four expected `IOHIDEvent*` symbols.
- CodeGraph remained unavailable with `Transport closed` on both post-write retries. The required pre-write CodeGraph context succeeded; final source correctness is supported by direct compiler, test, diff, binary, and archive evidence.
- `xcrun devicectl list devices` reports no connected target device, so Command+A/C/V/Z, an app-specific Command shortcut, and one Control/Option combination remain target-iPad acceptance items.

## Held Shift with HID arrows bug

- The user completed every Function 05 device-acceptance item successfully, including Command+A/C/V/Z, an app-specific Command shortcut, and Control/Option combinations.
- Device reproduction then found that holding Shift while pressing arrow keys moves the caret instead of continuously extending selection.
- Direct source evidence shows `KeyKind.shift` has no `MBHIDKey`, and `shftdown/shftup/shftcncl` only mutate `InputState` plus keycap presentation. The foreground app never receives Shift HID down/up.
- Arrow handlers independently dispatch only their arrow usage through `HIDBridge`; therefore the foreground app correctly interprets the event as unmodified caret movement.
- `InputState.shftused` is set only by proxy character emission and drag output, so a Shift+arrow chord also fails to mark the held Shift gesture as used and may leave an unwanted one-shot Shift latch after release.
- Apple IOKit usage declarations confirm Left Shift `0xE1` and Right Shift `0xE5`.
- CodeGraph impact is limited to the shared `InputState` transitions and keyboard controller touch/HID routing. Layout, host app, entitlements, and the single HID client are unaffected.
- The approved repair tracks left/right physical Shift keys inside the existing Shift state machine, dispatches their independent HID lifecycle, and marks the state used when another HID key begins; ordinary Shift-only proxy character output remains unchanged.
- The implemented `InputState` now owns a `Set<ShiftKey>` so simultaneous left/right holds release independently while the original one-shot, Caps Lock, character, drag, and cancellation transitions remain intact.
- Both Shift keycaps send their verified HID usages on touch down/up/cancel. Arrow, trackpad-direction, Delete, ordinary control, and Control/Option/Command entry paths mark a held Shift gesture used, preventing a post-chord one-shot latch.
- The existing `HIDBridge.activeKeys` set and `releaseAll` path already support the two added usages, so rebuild, disappearance, and teardown require no second HID client or cleanup mechanism.
- Local evidence is complete: 34/34 shared tests, `DESIGN.md` lint, iPad Pro simulator Debug, generic arm64 Release, ZIP integrity, version, architecture, HID imports, and entitlements all pass. Continuous selection behavior still requires target-iPad touch acceptance because the simulator cannot reproduce this private-HID keyboard-extension flow.

## Task 06 Sticky Modifier baseline

- The worktree is clean at `43f2ee1`. The accepted Function 05 implementation already provides one `HIDBridge`, five physical Ctrl/Option/Command usages, full visible-key HID mappings, and cyan active-key styling; Task 06 should extend state transitions only.
- `ModifierState` currently stores one active set, so touch-up always releases HID. It cannot distinguish an ongoing finger hold from a one-shot Sticky lock or remember whether another key participated in the touch.
- Modifier touch-up-inside, touch-up-outside, touch-cancel, and drag-exit currently share `modup`; Sticky requires separating successful tap completion from cancellation so abnormal endings can never create a lock.
- A robust model needs three facts per modifier source: physically held, Sticky, and whether the current physical touch was used in a chord. The HID-active state is the union of held and Sticky sources.
- Consuming Sticky after a successful non-modifier HID key must release only Sticky sources that are no longer physically held. This preserves physical-hold behavior when a user touches an already-Sticky modifier and then forms a chord.
- Modifier key taps are not themselves effective keys, so several Sticky modifiers can be combined before the foreground-app key is sent. Shift remains its existing independent modifier state and must not prematurely consume Ctrl/Option/Command Sticky state.
- The existing `DESIGN.md` selected-state rule already provides the requested clear highlight. Reusing that primary-cyan state plus “已按下”/“已锁定” accessibility values is sufficient and avoids a new visual token.
- Existing cleanup is duplicated between rebuild and disappearance. Task 06 should centralize modifier/Shift state reset, HID `releaseAll`, and keycap refresh, then call it from input-mode and application-lifecycle exits as well.

## Task 06 local validation

- Apple SDK declarations confirm keyboard extensions receive `.NSExtensionHostWillResignActive` and `.NSExtensionHostDidEnterBackground`; these extension-specific notifications are preferable to app-only lifecycle assumptions.
- The implemented `ModifierState` keeps held, Sticky, and used sets. `consume()` clears Sticky sources but returns only those no longer physically held, so one effective HID key cannot release a modifier finger that is still down.
- `BoardButton.hidactive` makes Esc/arrow touch completion idempotent after lifecycle resets. A late touch-up after `releaseAll` no longer consumes or recreates modifier state.
- System next-keyboard touch-down releases HID before UIKit opens or changes the input-mode list; internal language rebuild, dismissal, view disappearance, extension-host resignation/backgrounding, and abnormal modifier cancellation use the same reset path.
- The full shared suite passes 40/40, `DESIGN.md` lint has zero findings, the M1 12.9-inch iPad Pro simulator Debug build succeeds, and generic iOS Release packaging succeeds.
- Final artifact `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` is version `0.7.0 (16)`, 158,950 bytes, SHA-256 `3d9244cb477865157d44eb76b9599a3b368c50298c6836b0fdcd24b59b6c87d9`, from source commit `0e7340d`.
- Independent extraction confirms ZIP integrity, arm64 host/extension executables, matching versions, the keyboard extension point/open-access flag, IOKit linkage and four HID imports, host App Group only, and keyboard App Group plus HID event-dispatch entitlement.
- A first entitlement-inspection pipeline asked `plutil` to read an unavailable standard-input representation. The alternative `codesign -d --entitlements -` display succeeded and confirmed both entitlement sets.
- `xcrun devicectl list devices` reports no connected device, so real multi-touch Sticky behavior, focus/input-mode exits, background transitions, and full regression acceptance remain Phase 36.

## Task 06 Tab follow-up baseline

- CodeGraph confirms `KeyKind` has no Tab case or HID mapping; Tab therefore cannot enter the already-correct generic HID down/up path or trigger Sticky consumption.
- `DESIGN.md` already fixes Tab's desired presentation: lowercase word legend, leading lower-left alignment, and 1.5-unit width matching Esc. The follow-up must enable the existing key in place rather than alter layout or add a visual rule.
- The correct minimal integration surface is the existing HID enum, `KeyKind.hidKey`, current Tab `KeySpec`, and accessibility label switch. No shared modifier state, shortcut table, second event client, or host-app logic is needed.

## Task 06 Tab follow-up validation

- Apple's installed HID usage declaration confirms Keyboard Tab is usage `0x2B`; the bridge now exposes that exact value and `KeyKind.tab` maps to it.
- Replacing the existing placeholder spec with the existing enabled-control factory preserves Tab's 1.5-unit geometry, lowercase leading legend, generic HID down/up/outside/cancel lifecycle, and successful-key Sticky consumption without adding a parallel path.
- The existing iPad Pro 12.9-inch 2018 simulator visibly shows Tab in place with the accepted functional-key treatment. A live Ctrl Sticky tap highlights Ctrl, and completing Tab clears that highlight.
- The full shared suite remains green at 40/40, `DESIGN.md` lint has zero findings, simulator Debug and generic arm64 Release builds succeed, and the prohibited local-Shell scan and diff checks pass.
- Rebuilt `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` remains version `0.7.0 (16)`, is 159,680 bytes, and has SHA-256 `6be54d51d8f3ca5eeecd2177083a5d32d4ba1d4eb4fa19a226e560c25d745bd4` from source commit `351ee21`.
- Independent extraction confirms ZIP integrity, arm64 host/extension binaries, matching bundle versions, both expected plists, required IOKit HID imports, host App Group only, and keyboard App Group plus HID event-dispatch entitlement.

## Task 06 modifier-toggle conflict diagnosis

- Direct CodeGraph evidence identifies `ModifierState.tap()` as the root cause: a clean modifier tap removes the physical `held` source, inserts it into `sticky`, and deliberately leaves the HID usage down until a later effective key consumes it.
- Apple documents that holding Command displays shortcuts for the current app, so the reported shortcut-guide overlay is the expected system response to MagicBoard's raw held Command state: `https://support.apple.com/guide/ipad/use-shortcuts-ipaddf61a0c2/ipados`.
- Apple documents that Hover Text uses a held Control key by default and allows its activation modifier to be changed to Option or Command. A raw Sticky modifier can therefore keep an accessibility overlay active depending on user settings: `https://support.apple.com/guide/ipad/view-a-larger-version-text-reading-typing-ipad8c381980/ipados`.
- Apple documents Control–Option as a selectable VoiceOver modifier and assigns many navigation commands to Option and Control combinations. Retaining independently held raw modifiers can interact with accessibility navigation when those features are enabled: `https://support.apple.com/guide/ipad/use-voiceover-with-an-external-keyboard-ipad9a246749/ipados`.
- iPadOS itself offers hardware-keyboard Sticky Keys for sequential shortcuts, confirming that one-shot modifier UX is valid; the conflict is specifically MagicBoard's idle raw HID-down implementation rather than sequential shortcuts as a concept: `https://support.apple.com/guide/ipad/adjust-keyboard-settings-ipad424a3e13/ipados`.
- Safest minimal policy is to remove tap-to-Sticky from Command, Control, and Option while retaining physical multi-touch. A more involved alternative is to retain selected logical Sticky state locally, release HID during idle, and synthesize modifier down/up only around the next effective key.
- User selected the safest minimal policy: remove Sticky for all Ctrl/Option/Command sources and preserve only the already-working physical multi-touch down/up interaction.
- The implementation can reuse the repository's pre-Sticky `ModifierState` shape from the parent of commit `6d9fc58`, while retaining Task 06's later unified HID reset, lifecycle cleanup, and failure recovery.

## Task 06 modifier-toggle fix validation

- The focused clean-tap test failed before implementation for all five modifier sources: each source remained contained and kept `isActive = true`, producing 10 expected assertions and no unrelated failures.
- Final `ModifierState` retains one active physical-source set plus `press`, `release`, `tap`, and `reset`; the Sticky/used sets, lock query, consume path, HID remapping helper, and “已锁定” accessibility state were deleted.
- Controller touch-down still sends modifier HID down and highlights the key. Both successful touch-up and abnormal cancellation now remove the physical source and send HID key-up; the existing `rsthid()` lifecycle safety path is unchanged.
- The shared suite passes 35/35, `DESIGN.md` lint has zero findings, the iPad Pro 2018 simulator Debug build succeeds, and the prohibited local-Shell scan is empty.
- Simulator interaction confirms left Command returns to its normal appearance and shows no shortcut guide after a three-second wait; Control and Option also return immediately after clean taps.
- Installing the updated simulator build reset Full Access. After explicit user approval it was restored; the user then clarified and performed the required input-method gesture: hold/drag the Globe control to the MagicBoard menu item and pause there before release.
- Release packaging succeeds from source commit `1679abc`. `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` remains `0.7.0 (16)`, is 151,470 bytes, and has SHA-256 `c76b8342a46c430529c81f12b09551af10d1f0a02be9f98e0e1014f1bbc49074`.
- Independent validation confirms ZIP integrity, arm64 host/extension binaries, required HID imports, host App Group only, and keyboard App Group plus HID event-dispatch entitlement. CodeGraph is healthy with 8 files, 196 nodes, and 206 edges.

## Task 06 F1–F12 follow-up baseline

- Live simulator acceptance proves the completed Tab mapping is functional: from the first field of `https://httpbin.org/forms/post`, MagicBoard Tab moved focus to the Telephone field. Safari then selected its number-oriented keyboard for the `tel` field, which is expected input-type behavior.
- The user selected a dual-layer contract: normal touches send standard F1–F12; holding either physical Shift sends the stacked icon's system action.
- Apple's installed `IOHIDUsageTables.h` confirms Keyboard F1–F12 as `0x3A...0x45`, Consumer brightness `0x70/0x6F`, show-all-windows `0x29F`, search `0x221`, voice command `0xCF`, previous/play-pause/next `0xB6/0xCD/0xB5`, mute `0xE2`, and volume decrement/increment `0xEA/0xE9`; Generic Desktop Do Not Disturb is `0x9B`.
- The approved TrollVNC reference already sends Consumer-page brightness, media, volume, and search through the same `IOHIDEventCreateKeyboardEvent` function and tracks active keys as `(page << 32) | usage`. MagicBoard can adapt that page-aware state into its existing bridge without a second client or entitlement.
- Because Shift can be released before the F key touch ends, the selected standard/system usage must be stored on `BoardButton` at touch-down and reused at key-up/cancel. Recomputing from the current Shift state would risk an unmatched HID key.

## Task 06 F1–F12 local validation

- `HIDBridge` now preserves its existing keyboard API while internally tracking active events as `(page << 32) | usage`; `releaseAll()` decodes and releases every Keyboard, Consumer, or Generic Desktop event through the same client.
- Direct Simulator browser evidence reports MagicBoard F1 as `event.key/code = F1` and key code 112, F6 as F6/117, and F12 as F12/123. This verifies the endpoints and midpoint of the contiguous Keyboard F1–F12 mapping without invoking the icon layer.
- The top row remains in the same fixed geometry with the same F captions, outline SF Symbols, stacking, font sizes, and spacing; all twelve keys now use the enabled functional-key appearance.
- The full shared suite passes 35/35, `DESIGN.md` lint has zero findings, the iPad Pro 2018 simulator Debug build succeeds, and the generic iOS arm64 Release package succeeds.
- The only installed Simulator runtime is iOS 18.4, and Computer Use cannot synthesize the required simultaneous Shift touch plus F touch. The iPadOS 16.x response to show-all-windows, search, voice command, and Do Not Disturb usages remains a target-device acceptance item.
- Final artifact `/Users/mac/codexproj/magicboard/build/MagicBoard.tipa` remains version `0.7.0 (16)`, is 151,842 bytes, and has SHA-256 `6ce6acd207b30f36b9bf115cb6c5cc15822be165b24020a8784aeafca3c31cd3` from source commit `496cf91`.
- Independent extraction confirms ZIP integrity, arm64 host/extension binaries, matching versions, keyboard extension identity/open access, IOKit linkage and four HID imports, host App Group only, and keyboard App Group plus HID event-dispatch entitlement.

## 2026-09-02 — F-row dual-layer interaction impact

- The existing F keys dispatch HID on `touchDown`, while dual-layer character keys defer output until the Pan gesture completes. Adding the Pan recognizer without changing dispatch timing would send a normal F key before a downward drag could select the icon action.
- The smallest safe integration is to reuse `dragkey`, `begdrag`, `upddrag`, and `rstdrag`, but make F taps store their selected layer at touch-down and dispatch a complete down/up pair only on `touchUpInside`.
- Existing transient drag layers are labels. Supporting the already-present F-row SF Symbols requires widening only the upper transient view to `UIView`; the lower F caption remains a label and the same transforms apply to both.
- `InputState.shifted` already represents both one-shot and held Shift, while `shiftHeld` distinguishes the physical sources. F-row presentation should use `shifted`; a successful F action needs one focused transition that clears one-shot Shift or marks held Shift used without changing Caps Lock.
- F-row geometry, weights, symbols, colors, HID mappings, entitlement scope, and the single event bridge are outside the change surface.

## 2026-09-02 — F-row dual-layer validation

- The shared state suite passes 37/37, including one-shot consumption plus held-Shift/Caps preservation. `DESIGN.md` lint reports no findings, and both the iPad Pro 2018 simulator Debug build and generic arm64 Release build succeed.
- Simulator visual acceptance confirms one-shot Shift removes all F captions and centers the existing SF Symbols. F10 then restores the stacked row automatically, Shift+F4 opens system search, and an unshifted F1 still reports standard JavaScript key code 112.
- Computer Use mouse drags do not trigger the already-accepted character-key Pan gesture either, so the absence of an automated F-row drag result is an input-synthesis limitation rather than a functional comparison failure. Physical touch remains the authoritative motion acceptance.
- The rebuilt TIPA is 154,072 bytes with SHA-256 `bc8e7800c2fb55f8ab4a8f91c730753be420a34de9342c49d142fd59ca703125`; ZIP, arm64 binaries, version parity, IOKit linkage/imports, and `ldid` entitlements all pass independent inspection.

## 2026-09-05 — Companion route indicator design baseline

- The approved product model separates companion capability from the active keyboard route: enabling the companion permits remote routing but does not select it.
- Route selection is intentionally session-local and starts in Local whenever the keyboard extension process creates a new controller.
- The candidate strip trailing edge is the approved control surface because it stays visible without moving the accepted six-row key grid.
- The minimum control is a fixed-width text-only capsule with three states: Local, Remote Keys, and Remote Full. Host-app whitelisting and simultaneous local/remote dispatch are excluded.
- CodeGraph identifies `setupCandidateBar`, `renderCandidates`, and `updateCandidateColors` as the existing candidate-strip surface; no second strip or overlay is needed.
- Existing dispatch exits are centralized in `inptxt`, `sndhid`, `sndfn`, `arrdown`/`arrup`, and the modifier handlers. Route selection can reuse these exits instead of duplicating protocol or HID logic.
- CodeGraph's impact result is controller-wide because UIKit targets/callbacks are dynamically connected; implementation validation must rely on focused tests plus compilation rather than treating the coarse 85-symbol list as a reason to refactor the controller.
- Pre-change validation is functionally green: all 51 shared-config tests, all 13 protocol tests, and the remaining functional bridge tests pass. The sole failure is the existing `CompanionBridgeTests.testmem` benchmark at 114,688 bytes versus its 102,400-byte limit, so it is tracked as baseline noise rather than folded into this feature.
- Full-route review found that the former global `fullKeyboard` branch covered ordinary character keys but not Enter, Space, or unmodified Delete. The new session route therefore applies to those three existing exits too, including Delete auto-repeat, so “Remote Full” matches its visible promise.
- Signed simulator installation was necessary for an honest active-state check: the unsigned build displayed the disabled Local capsule because its App Group entitlement was unavailable, while the signed build exposed `group.com.iwmei.magicboard` and visibly cycled Local → Remote Keys → Remote Full.
- Final validation is green: 76 shared tests, signed iPad simulator Debug build, `DESIGN.md` lint, generic arm64 Release build, TIPA integrity, entitlement checks, and embedded Rime resource checks all pass.

## 2026-09-02 — Task 07 visual baseline

- `DESIGN.md` already defines every required design-system section and explicitly selects native iPadOS character, dynamic system colors, continuous 10–14 pt key radii, soft layered shadows, adaptive keyboard geometry, and selected-state cyan. No design interview or new theme file is needed.
- The accepted keyboard is one UIKit file. `BoardButton` currently stores only interaction state; `mkkey` embeds all fills and `UIButton.Configuration`, while `rfrshft()` and `updmods()` duplicate selected/normal color decisions. There is no reusable `KeyView` visual component yet.
- Current ordinary keys use translucent cyan and function keys translucent orange. Those brand tints diverge from the native iPadOS key hierarchy requested for Task 07; brand cyan should remain only as a selected-state signal.
- Current outer inset is 8 pt, inter-row gap 6 pt, inter-key gap 5 pt, arrow-pair gap 3 pt, and corner style `.medium`; no explicit border/shadow/pressed depth exists.
- The fixed six-row Mac layout, weights, label sizes, icon placement, dual-layer drag overlays, and HID handlers have prior simulator/device acceptance and remain outside the visual refactor.
- Available validation includes iOS 18.4 simulators for iPad Pro 13-inch (M4), iPad Air 13-inch (M3), and the existing custom 12.9-inch M1/2018 profiles. The requested 13-inch portrait/landscape visual matrix can be exercised locally; iPadOS 16.x visual confirmation remains a physical-device handoff.
- Apple documents `UIButton.configurationUpdateHandler` as the supported closure for updating a configuration when button state changes, with signature `(UIButton) -> Void`; this is the correct single path for normal, highlighted, selected, and disabled key visuals.
- Apple documents that `userInterfaceStyle` follows the device appearance by default and that dynamic `UIColor` values resolve through a trait environment. Because the project targets iPadOS 16, `KeyView` must explicitly request a visual refresh from `traitCollectionDidChange` rather than depend on iOS 18 automatic trait tracking inside configuration update handlers.
- Apple recommends resolving dynamic colors to `CGColor` inside `traitCollection.performAsCurrent`; the key shadow/border layer colors should follow that pattern so layer-backed depth updates correctly in light and dark appearances.

## 2026-09-02 — Task 07 visual validation

- A single `KeyView` now owns ordinary/function semantics and normal, highlighted, selected, and disabled styling. Controller refresh paths only update semantic state, removing the former duplicate Shift/modifier fill logic without changing HID or gesture routing.
- The first compact-height attempt exposed a deterministic portrait failure: a 340-point keyboard minus 17 points of vertical inset and 35 points of row spacing leaves 48 points per row, while two 22-point legend lines plus button content inset cannot fit. Restoring the 430-point full-size cap fixes the overflow without per-key font hacks.
- On the preserved iPad Pro 12.9-inch 2018 simulator, portrait light and dark screenshots keep number/symbol and punctuation pairs fully within each 7-point keycap. Landscape dark retains the same six-row hierarchy; active Shift is visually distinct and accessibility reports both Shift keys as selected.
- Switching the simulator appearance changes the keyboard background, ordinary key surface, function surface, labels, borders, and shadows automatically through UIKit dynamic colors; there is no duplicate light/dark keyboard tree.
- Final verification passes 37 shared tests, zero design-lint findings, simulator Debug, generic arm64 Release, ZIP integrity, arm64 and version parity, and entitlement checks. The package is `0.8.0 (17)` with SHA-256 `462303f384170883e7c89b9b59f234e22b34e06eb87888563ba2fbcda292604d`.
## 2026-09-03 — Task 09 初始勘察

- Git 工作区干净，当前基线提交为 `b11d1fe docs: record simulator keyboard diagnosis`。
- CodeGraph 索引健康：8 个文件、239 个节点；核心入口为 `App/MagicBoardApp.swift`、`Keyboard/KeyboardViewController.swift` 与共享包 `SharedConfig.swift`。
- 主 App 当前只有安装说明、App Group 诊断与固定青橙主题同步；并非完整设置页。
- `SharedConfig` 当前只持久化 `BoardTheme`，App Group 为 `group.com.iwmei.magicboard`。
- Keyboard Extension 当前仅在 `viewWillAppear` 调用 `SharedConfig.ldthm()`，所以已有“再次显示时刷新”的最小链路，但尚不能读取布局、反馈、Modifier 或中文方案配置。
- 当前 `InputState` 的 `.chinese` 只改变状态/字符符号，并未形成拼音转汉字候选引擎；全拼/双拼的真实验收边界需在编码前核清。
- 仓库已有完整 `DESIGN.md`；Task 09 属于用户明确批准的设置扩展，可在现有原生 iPadOS 视觉规则上增补设置组件规范。
- 用户确认 Task 09 要实现真实中文候选输入；双拼需覆盖全部主流方案并将微软双拼排在首位，同时尽可能继承本机已有输入习惯。
- Apple `UILexicon` 是自定义键盘可用的公开补充词典，包含常用词、联系人中的未配对姓名和系统文本替换，可用于降低迁移成本；它不是 Apple 拼音学习模型的完整导出。
- Rime 官方 `rime-double-pinyin` 当前列出六种标准方案：自然码、智能 ABC、小鹤、微软、拼音加加、四通；可作为“全套主流方案”的明确集合。
- 现有 `refrence/Hamster` 是 MIT 授权的成熟 iOS Rime 实现，但仓库不包含二进制 framework；需从 `amorphobia/LibrimeKit` release 获取静态 iOS framework，并单独准备 Rime schema/词典资源。
- Apple 公开文档说明未开启完全访问时自定义键盘不能访问扬声器；低频脉冲反馈必须以 `hasFullAccess`、内置扬声器路由和用户开关三者共同作为启用条件。
- 引擎比较结果：AOSP PinyinIME 是 Apache-2.0、约 1 MB 系统词典、纯 C++ 解码核心，仅 `userdict.cpp` 的 Android 日志头需要原生 iOS 适配；但它原生只负责全拼，六套双拼仍需额外解析层。
- 更契合本次功能的是 `zhanggenlove/LibrimeKit`：BSD-3-Clause SwiftPM 封装，release 固定校验和，提供 iOS arm64 真机与 Apple Silicon 模拟器切片，公开候选、选词、组字、提交、schema 切换 API；上游提交固定为 `efcb049af1cd854b16e5d248afbcac71ace02cc3`。
- Rime 官方资源已固定参考提交：`rime-prelude@082425e`、`rime-luna-pinyin@56b934b`、`rime-essay@e9b1a37`、`rime-double-pinyin@01a1328`。其方案资源采用 GPL-3.0，若随包分发必须保留源码资源与许可证/署名；LibrimeKit 及二进制依赖为 BSD/Boost/Apache/MIT 等宽松许可证。
- TrollStore 的 `.tipa` 只改变安装/签名路径，不会自动让 App 或 Keyboard Extension 脱离沙箱。读取 Apple 拼音私有学习模型需要新增高风险私有 entitlement/文件访问路径，不能等同于普通 `.tipa` 能力。
- 系统公开可复用范围包括：`UILexicon`（常用词、联系人姓名、文本替换）、`UITextInputTraits`（输入类型、自动大写/智能标点等宿主规则）、当前音频 route/output volume；这些应作为默认继承路径。
- 用户选择完全私有迁移、布局精细滑杆和混合 Modifier 默认语义。
- 系统启用列表可从 `.GlobalPreferences` 的 `AppleKeyboards` 读取；多个现有 iOS 键盘项目用扩展 bundle ID 前缀判断“已添加”，同时用扩展心跳区分“已添加”和“当前实际加载”。
- Apple 键盘学习数据的取证证据路径为 `/private/var/mobile/Library/Keyboard/<language>-dynamic.lm/dynamic-lexicon.dat`，使用统计在 `user_model_database.sqlite`；前者可提取字符串但格式未公开，后者记录通用 key/value 使用模型，均不能直接等价转换为 Rime 的拼音词频。
- 完全私有迁移涉及用户实际输入历史，必须设计为主 App 内显式操作、只读源文件、本机转换、可预览数量且默认不自动扫描；Keyboard Extension 只消费导入后的 App Group 数据。
- `LibrimeKit` 的 arm64 真机/Apple Silicon 模拟器切片可直接融入现有原生扩展，无需兼容层；模拟器已生成七种方案的 `.bin`/`.prism.bin`/`.table.bin`，证明资源部署与编译链路有效。
- Rime 启动自检使用全拼输入 `nihao` 并检查非空候选，随后恢复用户方案；扩展若失败会保留直接拉丁输入回退。
- `UILexicon` 可在公开 API 范围内补充通讯录姓名与系统文本替换，但不能导出完整 Apple 拼音学习模型；当前实现将匹配词追加在 Rime 候选后，避免改变主要候选习惯。
- 现成键盘应用 Clink 的当前 App Store 界面把预览、外观、布局、声音和触感拆成短卡片，并合并相近操作；该信息结构适合 MagicBoard，但其手机 Tab Bar 和 iOS 26 Liquid Glass 不适合本项目的 iPadOS 16 基线。
- MagicBoard 因此采用原生 `NavigationSplitView` 常驻边栏、圆角材质卡、两列状态块和预览优先结构；不复制 Clink 素材或手机导航。
- 实体机尚未连接；Apple 私有学习数据迁移及 `com.apple.private.security.no-sandbox` 继续按用户选择暂缓，不进入本次 TIPA。
- 私有设置深链 `App-Prefs:root=General&path=Keyboard/KEYBOARDS` 对应“通用 > 键盘 > 键盘”；旧实现的偏差来自失败后回退 `UIApplication.openSettingsURLString`，会打开 MagicBoard 的 App 设置页。
- 主 App 的图文并列来自边栏 `Label`、品牌状态、设置卡标题、状态块、主按钮、反馈提示和输入测试提示；统一改为纯文字后无需触及共享设置或 Keyboard Extension。
- 新增非可选 Codable 字段若继续使用合成解码，会使旧 `magicboard.settings.v1` 数据整体解码失败；`chineseEnabled` 因此使用兼容解码，旧配置缺失该字段时默认 `true` 并保留原方案、外观和布局。
- 截图中的菜单式 Picker 只露出当前值与双向箭头，不适合同时比较七种拼音方案；自适应文字选项网格可在 iPad 双栏宽度下直接展示全部方案，并把不可选五笔保留在同一视觉集合。
# Task 10 initial findings — 2026-09-04

- Git worktree started clean on `master` at `34ad0df`; no remote is configured.
- CodeGraph is healthy: 11 indexed files, 386 nodes, 393 edges.
- `KeyboardViewController.viewWillDisappear` calls `stopcursor()`, `stopdel()`, then `rsthid()`.
- `rsthid()` clears Shift/modifier/latch/touch state, stops timers, calls `HIDBridge.shared.releaseAll()`, and refreshes visible modifier state.
- The existing `scripts/build-tipa.zsh` is native Zsh and already performs Release build, staging, xattr/signature cleanup, per-binary `ldid` signing, App Group/HID entitlement checks, host/extension version parity, open-access validation, and ZIP integrity checks.
- The only booted simulator is iOS 18.4 `MagicBoard iPad Pro 12.9 2018` (`iPad8,5`); installed user app inventory currently contains MagicBoard and no obvious third-party editor/terminal app.
- One inspection command used the nonexistent macOS path `/usr/bin/test`; this was a tooling-path error only. Subsequent checks use `/bin/test`.
- Baseline verification passed: 49/49 shared tests and `DESIGN.md` lint with 0 errors, warnings, or infos.
- Safari accepted ordinary MagicBoard text through its address field; the exact observed intermediate value was `tedt`, confirming four sequential proxy insertions.
- Safari/Toptal observable HID results: Esc cancelled address editing; ArrowLeft/Up/Down/Right reported JavaScript key codes 37/38/40/39.
- Safari observable shortcut results: Command-L selected the address field; Option-Left moved from the end of `one two` to the beginning of `two`, after which insertion yielded `one xtwo`; Ctrl-A moved to the line start, after which insertion yielded `zone xtwo`.
- Modifier keycaps returned to their unselected appearance after each consumed shortcut; no visual modifier residue appeared.
- Five complete MagicBoard ↔ system keyboard transitions succeeded in the same Safari input session and preserved field content.
- Four consecutive orientation changes preserved `zone xtwo`, kept the keyboard responsive, and showed no clipping in portrait or landscape.
- Four Safari background/foreground cycles preserved the focused field, content, and restored MagicBoard without a hang or visible residue.
- Reminders first-run setup completed locally, then its reminder title field accepted `note` from MagicBoard and exposed `Value: note` through accessibility.
- The simulator does not contain Notes, a third-party native app, or a terminal/code editor; those exact host categories remain unavailable locally.
- Computer Use initially referenced non-persistent `fs`/`url` variables and raised `fs is not defined`; the session was corrected by storing imports on `globalThis`.
- One attempt clicked a stale accessibility index after the Safari tree changed; a fresh state plus a safe coordinate click closed the transient menu without changing data.
- A local `data:` page with `input type=password` invoked only the built-in iPadOS password keyboard; MagicBoard did not remain visible in the secure field.
- Entering the system Passwords app removed MagicBoard without a crash or overlay anomaly. No notification permission was accepted because it was unnecessary for keyboard validation.
- Killing the live extension process PID 29693 caused immediate system-keyboard fallback. Switching keyboards relaunched the extension as PID 59233; it rendered normally and inserted `r` into the host test field. No MagicBoard diagnostic crash report exists.
- Unified logs contain expected simulator/runtime noise (`Sole personality is ambiguous`, CoreMedia allocation warnings) and App Group lookup errors because the currently installed simulator binary has no embedded signing entitlements. Source entitlements and the TrollStore Release signing flow still declare the App Group; final archive inspection remains authoritative for device delivery.
- `docs/magicboard-simulator.png` is a 2048×2732 real CoreSimulator capture showing the host input-test page and full keyboard after recovery. CoreSimulator exported it 180° from the visible window, so the original was backed up and the deliverable was rotated 180° once, then visually verified upright.
- The create-readme badge script succeeded and generated `assets/readme-badge.png` with label `magicboard`.
- README inspiration review selected the concise patterns common to the supplied repositories: centered visual header, a short value statement, installation near the top, restrained admonitions, focused feature/architecture/build sections, and screenshots close to the introduction.
- User selected final version `1.0.0 (19)` and a public same-name GitHub repository `MagicBoard`.
- The pre-release app had no asset catalog, no compiled icon files, and displayed the system placeholder icon in SpringBoard.
- Added an opaque 1024×1024 cyan/white/navy/orange AppIcon master aligned with `DESIGN.md`. Xcode `actool` compiled it without warnings and the installed simulator app now displays the intended keyboard mark in the Dock.
- Final TIPA icon audit confirms `Assets.car`, `AppIcon60x60@2x.png`, and `AppIcon76x76@2x~ipad.png` are present. The rebuilt archive is 6,629,114 bytes with SHA-256 `b348a53a1051e1e1eb159739bde7946b58abbc527acb5a707d86ad339e722a38`.
- Physical device crash analysis (iOS 16.6.1 TrollStore): verified zero iOS 17+ APIs used. Root cause was Jetsam dirty memory limit (~30MB–48MB for com.apple.keyboard-service). Online Rime schema and dictionary compilation during `viewDidLoad` peaked dirty RSS at ~194MB, triggering kernel SIGKILL.
- Strategy 1 implementation: precompiled all 7 Rime schemes offline into `.table.bin`, `.prism.bin`, `.reverse.bin` (~22MB total) under `Keyboard/RimeResources/build/`, configured `traits.prebuiltDataDir`, and switched `maintenance` to `false`.
- The binary dictionaries load via clean `mmap` read-only memory, reducing dirty memory footprint to ~15-25MB and fully resolving Jetsam crashes.
- Bumped version to `1.0.1 (20)`. User verified on physical iOS 16.6.1 iPad with TrollStore: instant keyboard display and stable input with zero crashes.

# Task 13–16 final acceptance findings — 2026-09-06

- Git baseline is clean on `master`.
- The only available simulator is booted: `MagicBoard iPad Pro 12.9 2018`, iOS 18.4, UDID `73860E49-6DDF-450B-B505-F0E0A09F764B`.
- MagicBoard host and keyboard-extension processes are already running in that simulator.
- SSH config contains one unambiguous Windows target: alias `windows`, host `10.1.1.2`, port 22, key authentication.
- Existing local verification already passes 86/86 shared tests, bridge latency 0.0048 ms average, 80 KB memory delta, design lint with zero findings, 13/13 cross-platform Windows Python tests, and TIPA ZIP integrity.
- Missing evidence remains Windows-host `SendInput` execution/UIPI state and the complete simulator-to-Windows/macOS live key matrices.
- Windows SSH read-only inventory confirms Windows 11 build 26200, PowerShell 7.6.5, Python 3.11, MSVC 14.44, and MinGW GCC are available; UDP 52088 is currently free.
- The first complex SSH `-Command` call exposed a remote argument-reparsing issue around `gsudo status`; its admin-state field is discarded, while the independently returned OS/tool/listener fields remain usable.
- The corrected PowerShell 7 `-EncodedCommand` check confirms the SSH identity is already an administrator at High integrity and the `gsudo` credential cache is available.
- No existing `magicboard` directory was found under the Windows user profile or shallow D:/F: search, so validation files must be copied into a new isolated target directory.
