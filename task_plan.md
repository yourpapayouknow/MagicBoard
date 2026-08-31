# MagicBoard Task 01 Plan

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
- Exact test-device versions and final `ldid` signing policy are not yet confirmed.

## Phases

### Phase 1 — Requirements and design alignment

**Status:** in_progress

- Complete the eight-section `design-md` interview, one section per user reply.
- Confirm technical stack, identifiers, deployment target, device/TrollStore environment, inputs/outputs, and exact success checks.
- Agree on the initial reference-repository shortlist before implementation.

### Phase 2 — Reference implementation research

**Status:** in_progress

- Add `/refrence` to `.gitignore`.
- Clone no more than 20 relevant repositories into `/refrence`.
- Record reusable approaches and adaptation levels in `/refrence/refrence.md`.
- Verify every external API/tool invocation against primary documentation, source, or type definitions.

### Phase 3 — Project scaffolding and configuration

**Status:** pending

- Create host app, keyboard extension, and shared module targets.
- Configure bundle identifiers, extension `Info.plist`, shared configuration mechanism, and entitlements.
- Verify project structure and build settings.

### Phase 4 — Minimal native test UI

**Status:** pending

- Implement the approved host app and test-keyboard interface using `DESIGN.md`.
- Add focused tests for shared/configuration logic and inspect built extension metadata.

### Phase 5 — Build and `.tipa` packaging

**Status:** pending

- Build with the confirmed signing/TrollStore strategy.
- Add a Zsh packaging script that produces `MagicBoard.tipa` reproducibly.
- Verify archive structure, identifiers, entitlements, and extension embedding.

### Phase 6 — Device installation and acceptance

**Status:** pending

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

## Completion checklist

- [ ] MagicBoard host app target exists
- [ ] Keyboard extension target exists
- [ ] Shared module/configuration exists
- [ ] Bundle identifiers and keyboard `Info.plist` are verified
- [ ] Shared container or confirmed equivalent is verified
- [ ] TrollStore entitlements are verified
- [ ] Zsh build/package script produces `MagicBoard.tipa`
- [ ] TrollStore installs the artifact successfully
- [ ] iPadOS Settings can add MagicBoard
- [ ] Switching keyboards displays the approved test UI
