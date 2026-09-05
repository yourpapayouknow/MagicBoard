# Findings

## Baseline

- Git worktree was clean at the start of the request on commit `06e1256`.
- No project runtime log file was found in the initial log/history scan.
- Existing `DESIGN.md` defines a fixed candidate strip, horizontal scrolling, Rime-first candidates, supplementary lexicon, and a fixed trailing routing capsule, but it has no custom-dictionary page specification.

## Candidate-selection root cause

- `renderCandidates` renders up to 20 engine candidates and assigns each button its enumerated position as `tag`.
- `selectCandidate` passes that tag to `RimeEngine.select`, which calls LibrimeKit `selectCandidateOnCurrentPage(index:)`.
- LibrimeKit source and ObjC headers explicitly define that API index as page-local. Its `candidateList()` documentation also describes a current-page view, while paginated reads require `candidateListWithIndex` and page changes require `changePage`.
- Therefore later rendered/global positions are invalid current-page indices. This directly explains why the first few candidates commit and later candidates silently fail.
- Candidate layout constraints correctly bind the row to `UIScrollView.contentLayoutGuide`; there is no evidence that touch hit-testing or the fixed route button is the cause.

## Existing dictionary and learning surface

- `luna_pinyin.schema.yaml` already includes `table_translator@custom_phrase` backed by a `custom_phrase` stable user database.
- The Rime user data directory is already placed in the App Group, so learned/user data can persist across host app and keyboard extension sessions.
- Librime exposes native user-dictionary import/export APIs through `rime_levers_api.h`; using those or the existing custom-phrase translator is preferable to inventing a second dictionary engine.
- Rime deployment/maintenance previously caused a confirmed keyboard-extension Jetsam event, so any import/rebuild work must run from the host app or use a lightweight shared-data path, never compile dictionaries inside the keyboard extension.
- Only the full-pinyin schema currently registers `table_translator@custom_phrase`; the six double-pinyin schemas do not, so relying on that translator alone would make user terms inconsistent across schemes.
- The existing `syscands` merge path already matches an input-code prefix and appends non-Rime candidates. Extending this path with an App-Group personal dictionary is the smallest native implementation that works for every scheme without schema compilation in the extension.
- Hamster's existing implementation copies user dictionary files and relies on librime user databases; it does not provide a smaller ready-made host-app CRUD/import surface that can be transplanted directly.
- The iOS 16 SwiftUI SDK exposes the single-file `fileImporter(isPresented:allowedContentTypes:onCompletion:)` overload, and Foundation exposes paired security-scoped URL access methods.
- The bundled `luna_pinyin.dict.yaml` confirms standard data rows are tab-separated term and code with optional additional columns after a YAML metadata block. YAML and plain TSV can therefore share one strict line parser.
- User confirmed: import Rime YAML and TSV; manual input is term + current-scheme code + optional weight; learning applies to every candidate source; proceed with implementation.
- The installed Apple toolchain exposes native SQLite 3.51.0 and the iOS SDK headers confirm `sqlite3_open_v2`, prepared statements, bound text, and full-mutex support.
- SQLite in the App Group is preferable to JSON/UserDefaults here: large imported dictionaries stay off the keyboard heap, prefix queries are indexed, learning updates are atomic, and no third-party dependency or Rime deployment is needed.
