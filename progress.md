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
