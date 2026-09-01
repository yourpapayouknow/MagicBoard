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
