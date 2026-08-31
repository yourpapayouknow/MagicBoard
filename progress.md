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
