# Candidate Selection and Custom Dictionary Plan

## Goal

Fix selection of every horizontally scrollable candidate, then add a native iPadOS custom-dictionary page that supports user-added terms, approved external dictionary import, and persistent candidate learning without duplicating the existing Rime pipeline.

## Success criteria

- Every visible candidate can be tapped after horizontal scrolling and commits the intended candidate.
- The fix preserves composition, candidate-strip routing, keyboard geometry, and accessibility.
- Users can add, inspect, and remove personal terms in the host app.
- The agreed standard import format is validated and imported with clear error reporting.
- Candidate choices update persistent learning/ranking according to the agreed scope.
- Existing settings remain backward compatible; focused tests, full tests, design lint, localization checks, and simulator builds pass.

## Phases

### Phase 1 — Evidence and requirements

**Status:** complete

- Inspect logs/history first, then map candidate rendering, scrolling, tap dispatch, Rime APIs, shared-container persistence, and existing reference implementations.
- Establish the candidate-selection root cause with direct evidence.
- Confirm import format, duplicate policy, and learning behavior with the user.

**Confirmed decisions:** support Rime `.dict.yaml` plus UTF-8 TSV; manual entries use term, current-scheme code, and optional weight; learn all candidate sources; continue with phased implementation.

### Phase 2 — Design and data model

**Status:** complete

- Add the approved custom-dictionary page rules to `DESIGN.md`.
- Define the smallest shared model and persistence boundary that reuses Rime where possible.
- Add failing tests for parsing, validation, compatibility, ranking, and candidate-index behavior.

**Selected model:** one App-Group SQLite database with indexed `(scheme, code)` terms and bounded per-candidate learning counts; host app owns import/edit operations, while the extension performs prefix reads and small learning upserts.

### Phase 3 — Candidate fix

**Status:** complete

- Apply the smallest verified fix to candidate selection.
- Verify early and later candidates, scroll position, composition, and routing-capsule coexistence.

### Phase 4 — Dictionary import, editing, and learning

**Status:** complete

- Implement the approved importer and personal-term CRUD in the host app.
- Feed personal terms and learned ranking into the existing candidate pipeline.
- Preserve shared-container safety and extension memory limits.

### Phase 5 — Verification and delivery

**Status:** complete

- Run focused/full tests, design lint, localization validation, simulator Debug, and proportionate interaction checks.
- Review the final diff, commit in recoverable increments, and report any physical-device-only acceptance item.

## Errors encountered

| Error | Attempt | Resolution |
|---|---:|---|
| Zsh reported `no matches found: refrence/rime-*` during a reference scan | 1 | The glob matched no directory; subsequent inspection uses only explicit existing paths and remains on `/bin/zsh`. |
| A combined candidate patch did not match the current class comment | 1 | No partial edit was applied; the patch was split into exact, smaller hunks. |
| A combined UI/localization patch targeted the same file twice | 1 | No partial edit was applied; source and localization patches were separated. |
| `LabeledContent` value overload rejected `LocalizedStringKey` | 1 | Switched both rows to content closures containing localized `Text`. |
| Existing Jetsam memory benchmark measured 112 KB against its 100 KB limit | 1 | The isolated rerun measured 96 KB and all 86 tests passed; no production code or benchmark threshold was changed. |
