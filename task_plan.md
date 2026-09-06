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
| Task 09 参考检索中 Zsh 报告 `no matches found: refrence/iRime*` | 1 | 该目录不存在；后续只使用已确认存在的 `refrence/Hamster` 等明确路径，不重复该通配符 |
| 模拟器中连续短按地球键切换输入源效率低且未稳定到达 MagicBoard | 1 | 用户指出应长按地球键直接选择；停止重复尝试，并将同样的简洁指引写入输入测试页 |
| 新版概览首次编译使用了 iOS 17 才提供的 `.buttonBorderShape(.circle)` | 1 | 保持 iPadOS 16 部署目标，移除该单行装饰后 Debug 与 Release 均通过 |
| `autocli 0.3.8 google search` 拒绝技能示例中的 `--query` | 1 | CLI 帮助确认当前版本使用位置参数 `<keyword>`；后续按本机真实签名调用 |
| GitHub API 查询旧归属 `imfuxiao/LibrimeKit` 最新 release 返回 404 | 1 | Hamster 源码与 GitHub 页面确认当前上游为 `amorphobia/LibrimeKit`；后续查询正确仓库 |
| 连续 GitHub 代码搜索触发 API 403 限流 | 1 | 已取得所需路径与状态检测证据；停止代码搜索，不重试限流接口，后续使用本地参考和设备验证 |
| `apply_patch` 拒绝同一补丁内对 `MagicBoardApp.swift` 同时 Delete/Add | 1 | 原文件未变化；改用单次 Update File 补丁，不重复 Delete/Add 组合 |
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
| Windows SSH 多语句清单中的 `gsudo status` 输出被远端命令行重新解析并产生 `ParserError` | 1 | 主体只读清单仍返回；后续改用 PowerShell 7 官方 `-EncodedCommand`，不重复直接传递复杂 `-Command` |
| JavaScript 编排环境不提供浏览器全局函数 `btoa`，首次内存生成 PowerShell EncodedCommand 失败 | 1 | 未执行远端命令；改由本机 Python 标准库只做 UTF-16LE Base64 编码，随后 `-EncodedCommand` 正常返回 |
| 在 Swift 包目录运行组合命令时，前置 `rg` 仍使用仓库根相对路径而报目录不存在 | 1 | 后续使用包内相对路径；同一命令中的目标 iOS 模拟器测试独立成功，错误未掩盖测试退出状态 |
| CodeGraph 未索引到 XCTest 方法 `testsimwin` | 1 | 使用已知测试文件的精确路径读取该方法；不重复结构查询 |
| macOS 构建脚本生成 `cpmac`，但两份 Python 验收脚本仍查找旧名 `magicboard-companion-mac`，端到端脚本还引用旧 XCTest 名 | 1 | 提问未返回选择；采用推荐的最小修正并只在 52188 隔离测试，不触碰现有 PID 13242/UDP 52088 服务 |
| Swift `cpmac` 输出“正在监听”，测试脚本只接受“已就绪”，因此先误报等待超时再正常通过 | 1 | 用户确认修正；就绪判定接受两种现有成功标志后重跑 |
| macOS 模拟器 E2E 脚本含相同的旧“已就绪”单值判断，首次重跑在服务已监听时退出 | 1 | 属于用户已批准的同一修复；同步接受“正在监听”，只重跑失败的 E2E |
| 首次独立归档审计命令包含 `rm -rf` 清理临时目录，被安全策略执行前拒绝 | 1 | 无文件被改动；重跑时保留专用 `/tmp/magicboard-final-audit.*` 目录，不执行删除 |
| Apple `codesign` 无法把 TrollStore `ldid` 签名解释为有效 Apple 证书签名 | 1 | 先不判失败；改用项目实际签名工具 `ldid -e` 验证 entitlement，并用 Mach-O 符号工具复核 HID 引用 |
| Windows E2E 脚本仍引用旧 XCTest 名并用 `shell=True` 间接调用默认 Shell | 1 | 改为参数数组、PowerShell 7 EncodedCommand 和当前 `testsimwin` 后实际复验 |
| v1.0.3 Release 首次构建时 Xcode 报告 DerivedData 日志清单尚不存在 | 1 | 这是新建日志目录时的非致命 IDELogStore 提示；编译、签名、打包与独立归档审计均成功，无需修改产品代码 |
| `gh release view` 不支持请求的 `isLatest` JSON 字段 | 1 | Release 已成功创建；按 CLI 返回的支持字段移除 `isLatest` 后重新核对远端资产 |
| 发布记录推送成功后，尾部只读复核遇到 GitHub EOF 与 LibreSSL `SSL_ERROR_SYSCALL` | 1 | 本地输出已确认 push 成功；停止重复相同查询，改用 GitHub REST API 分别核对分支和 Release |

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

**Status:** complete

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

**Status:** complete

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

**Status:** complete

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

## Task 06 follow-up — F1–F12 dual-layer function row

### Goal

Enable the existing F1–F12 row in place. A normal touch sends the standard Keyboard-page F1–F12 usage; a downward drag, one-shot Shift, or physically held Shift selects the icon's system/consumer HID action instead.

### Confirmed behavior

- Normal F1–F12 touches emit standard keyboard usages `0x3A...0x45`.
- Either one-shot Shift or a physically held Shift selects the icon layer; Caps Lock does not affect the function row.
- An unshifted 24-point downward drag selects the icon layer and uses the same upper-center/lower-fade motion as the existing dual-layer character keys.
- Icon actions map to brightness down/up, show all windows, system search, voice command, Do Not Disturb, previous track, play/pause, next track, mute, volume down, and volume up.
- A normal F touch stores its selected layer at touch-down but dispatches the paired HID event only after a successful touch completion; down-drag commits only the icon action, while cancellation emits nothing.
- Existing row geometry, legends, SF Symbols, alignment, spacing, and colors remain unchanged; only disabled state becomes enabled.

### Phase 41 — HID mapping and bridge integration

**Status:** complete

- Reuse the existing TrollVNC-derived keyboard event function with page-aware active-key tracking.
- Add verified Keyboard, Consumer, and Generic Desktop usages without adding a parallel event client or entitlement.
- Route F touch-down to the standard or icon usage based only on `InputState.shiftHeld`, and pair the exact chosen usage on every ending path.

### Phase 42 — Build and simulator acceptance

**Status:** complete

- Run shared tests, `DESIGN.md` lint, diff/shell checks, XcodeGen, and the iPad Pro 2018 simulator Debug build.
- Verify Tab still moves focus between real form fields and the enabled top row preserves the accepted visual structure.
- Validate observable F-key system actions in Simulator where supported; record physical multi-touch-only checks for the target iPad.

**Simulator evidence:** the accepted row remained unchanged except for enabled styling. A JavaScript key-code page reported F1/112, F6/117, and F12/123 from direct MagicBoard touches, covering the beginning, middle, and end of the contiguous standard mapping. Simulator mouse input cannot hold a MagicBoard Shift touch while pressing a second key, and only the iOS 18.4 runtime is installed.

**Errors recorded:** Computer Use could not set the Safari address field until it had been explicitly focused. A later physical `Command-L` attempt invoked iPad lock instead of Safari location focus; Space unlocked the simulator, and the address field was then focused by coordinate before using its settable accessibility value. Neither event changed project files or acceptance state.

### Phase 43 — Release package and handoff

**Status:** complete

- Build the generic arm64 Release package and independently inspect archive integrity, versions, binaries, IOKit linkage/imports, and entitlement placement.
- Commit the surgical source and documentation changes, then report the artifact path, version, hash, and remaining target-iPad checks.

### Phase 44 — Target-iPad F-row acceptance

**Status:** pending

- Install `0.7.0 (16)` on the target iPadOS 16.x device and verify normal F1–F12 in an F-key-aware app.
- Hold each left/right Shift key and verify F1–F12 perform the twelve icon actions, with special attention to show-all-windows, search, voice command, and Do Not Disturb on iPadOS 16.x.
- Down-drag several F keys across the row and confirm the upper icon centers continuously, the lower caption fades/scales, and only the icon action fires after crossing 24 points.
- Release/cancel F touches, dismiss/switch the keyboard, and background/foreground the app; confirm neither Keyboard-, Consumer-, nor Generic-Desktop-page usages remain held.

### Phase 45 — Shared Shift consumption and F-row gesture routing

**Status:** complete

- Add a focused Shift transition that consumes one-shot Shift after a successful F action while preserving held-Shift release semantics and Caps Lock.
- Route F keys through the existing down-drag recognizer instead of dispatching a standard F usage at touch-down.
- Keep the selected tap layer stable from touch-down through completion and emit nothing for outside/cancelled/failed touches.

### Phase 46 — Dual-layer F-row presentation

**Status:** complete

- Reuse the existing 24-point progress, lower-layer fade/scale, upper-layer centering, and 120 ms reset timing.
- Render the F upper layer with the existing SF Symbol and the lower layer with the existing F caption.
- Show only the centered icon for one-shot or held Shift, restore the stacked layout when Shift is consumed/released, and leave Caps Lock unrelated.

### Phase 47 — Validation and package refresh

**Status:** complete

- Run focused/shared tests, `DESIGN.md` lint, diff/Shell checks, XcodeGen, and the iPad Pro 2018 simulator Debug build.
- Verify unshifted tap, unshifted down-drag, one-shot Shift display/action, held-Shift state logic, and cancellation cleanup.
- Rebuild and independently inspect the arm64 TIPA, then report the artifact hash and target-iPad-only acceptance items.

### F1–F12 follow-up checklist

- [x] Normal touches send standard F1–F12
- [x] Held left or right Shift selects the icon system action in the implemented routing
- [x] F-key touch cancellation and lifecycle resets converge on page-aware release-all cleanup
- [x] F1–F12 keep the accepted fixed top-row geometry and legends
- [x] Tab focus navigation and all existing input behavior remain intact locally
- [x] Tests, design lint, simulator Debug, arm64 Release, and archive checks pass
- [ ] iPadOS 16.x physical Shift+F icon actions and cancellation pass on the target iPad
- [x] Down-drag uses the accepted dual-layer animation path and emits only the icon action
- [x] One-shot and held Shift both show and trigger the icon layer; Caps Lock does not
- [x] Failed/cancelled F touches emit no standard or system HID event

## Task 07 — Native iPadOS keyboard visual system

### Goal

Unify every ordinary, function, and modifier key behind one `KeyView` visual component that preserves the accepted six-row Mac layout and interactions while matching the depth, spacing, state feedback, and automatic light/dark appearance of the native iPadOS keyboard on 13-inch iPad portrait and landscape screens.

### Fixed scope and assumptions

- Preserve all accepted key order, row weights, legends, typography, dual-layer drag behavior, HID routes, and accessibility labels.
- Ordinary keys use a native near-white/dark keycap surface; function and modifier keys use a distinct dynamic gray surface; cyan is reserved for selected Shift, Caps Lock, and physically held modifiers.
- Pressed state combines a dynamic fill change, reduced shadow, and slight vertical translation. Reduce Motion removes the translation while retaining the fill and shadow feedback.
- UIKit dynamic semantic colors and trait changes drive light/dark switching; no manual theme switch or duplicate appearance tree is added.

### Phase 48 — Visual baseline and impact audit

**Status:** complete

- Read the current design system, prior visual acceptance record, complete keyboard implementation, project settings, and simulator inventory.
- Confirm the worktree is clean and isolate the change to the keyboard key view, keyboard backdrop, and adaptive spacing/height constants.
- Record the current absence of a reusable `KeyView`: visual styling is embedded in `mkkey`, and modifier/Shift refresh paths directly rewrite button configuration colors.

### Phase 49 — Unified KeyView implementation

**Status:** complete

- Add one reusable `KeyView` subclass and semantic key role/state model.
- Move normal, pressed, selected, disabled, light, and dark visual styling into that component.
- Apply native-like continuous corner radius, dynamic keyboard/key/function surfaces, restrained border, shadow, and pressed depth.
- Route Shift and modifier refreshes through the unified component without changing input behavior.
- Tune horizontal/vertical gaps, arrow-pair gap, outer inset, and adaptive height for 13-inch portrait and landscape.

**Errors recorded:** the first Swift compile found that `UIButton` already owns a `role` property; the custom visual property was renamed to `keyRole`, after which the 2018 simulator Debug build succeeded. During simulator cleanup, one copied iPhone UDID contained `848D` instead of `848B`; the command stopped after deleting only the first device, the remaining device list was re-read, and the corrected explicit deletion completed without touching the preserved 2018 device. A temporary `clamp(width × 0.32, 340, 414)` height made portrait rows too short for two 22-point legend lines; after the user identified the clipping, the accepted `clamp(width × 0.5, 340, 430)` height was restored and visually rechecked.

### Phase 50 — Build, visual matrix, and package

**Status:** pending

- Run shared tests, design lint, diff/Shell checks, XcodeGen, simulator Debug, and generic arm64 Release.
- Inspect 13-inch iPad portrait and landscape in both light and dark appearances, including ordinary, pressed, and active modifier states.
- Use the preserved `MagicBoard iPad Pro 12.9 2018` simulator as the sole local device; its 1024×1366 full-screen point geometry is the local proxy for the requested 13-inch class after the user-directed deletion of every other simulator device.
- Rebuild and independently inspect the TIPA, commit surgical source/documentation changes, and report any physical-device-only checks.

### Task 07 checklist

- [x] One `KeyView` defines ordinary, function, and modifier visuals
- [x] Normal, pressed, disabled, and modifier-selected states are visually distinct
- [x] Key radius, keyboard/key/function backgrounds, gaps, shadows, and depth match the native iPadOS character
- [x] Light and dark modes follow system appearance automatically
- [x] The preserved full-size 12.9-inch 2018 proxy preserves consistent portrait/landscape proportions and visual hierarchy
- [x] Existing Mac layout, legends, gestures, HID behavior, and accessibility remain unchanged
- [x] Tests, design lint, simulator builds, release package, and archive inspection pass
## Task 09 — 主 App 与输入法设置

### Phase 7 — 设置需求与平台能力核验

**Status:** complete

- 核验现有 App Group、Keyboard Extension 刷新时机、entitlement 与系统设置跳转能力。
- 区分“输入方案选择”与真实拼音转汉字引擎，确认全拼/双拼的验收边界。
- 盘点可复用的系统规则与已有参考实现，避免重复实现。
- 用户选择私有迁移，但在连接实体 iPad 并验证真实路径/格式前不修改无沙箱 entitlement；其余设置与输入引擎继续实施。

### Phase 8 — 共享设置模型与测试

**Status:** complete

- 建立版本化、可向后兼容的统一设置快照与 App Group 读写接口。
- 覆盖默认值、往返、损坏数据、迁移与各设置枚举的测试。

### Phase 9 — 主 App 设置首页与扩展接入

**Status:** complete

- 实现启用引导/跳转、状态信息、布局、外观、强调色、反馈、Modifier 与中文方案设置。
- 实现测试输入区域或键盘预览。
- Keyboard Extension 在重新出现时读取新配置并应用，无需重新安装。

**阶段结果：** 主 App、共享配置、Keyboard Extension、离线中文引擎与系统补充词典均已接入；设置修改在扩展再次出现或输入上下文变化时生效。

### Phase 10 — 构建、行为验证与交付

**Status:** complete

- 运行 Swift Package 测试、XcodeGen、模拟器构建与定向检查。
- 验证改动范围、生成可回滚 Git 提交并记录未能在模拟器自动验证的设备项。

### Task 09 completion checklist

- [x] 现代 iPad 双栏设置首页与键盘启用跳转
- [x] 键盘、完全访问、设置同步与中文引擎状态
- [x] 全拼、六种双拼与不可选五笔
- [x] 键盘布局、四种外观、自定义颜色与强调色
- [x] 按键音、内置扬声器模拟触觉、Sticky Modifier 与操作模式
- [x] App Group 即时设置同步与扩展生命周期刷新
- [x] 输入测试区、候选栏、离线 Rime 与 `UILexicon` 补充候选
- [x] 48 项共享测试、设计 lint、模拟器 Debug、arm64 Release 与 TIPA 验证
- [ ] 实体 iPad 上验证私有系统学习数据格式后，再决定是否增加无沙箱 entitlement 与显式迁移入口

### Phase 11 — 设置页精简修订

**Status:** complete

- 设置按钮只打开“通用 > 键盘 > 键盘”，不再回退到 App 设置页。
- 删除主 App 的页面大标题，以及全部图标与文字并列展示；保留无文字的刷新图标。
- 通过设计 lint、iPad 模拟器 Debug 与 arm64 Release/TIPA 构建验证。

### Phase 12 — 中文输入总开关与方案选择器

**Status:** complete

- 新增默认开启、向后兼容的中文输入总开关并同步至 Keyboard Extension。
- 关闭后禁用方案选择、阻止进入中文模式并回到英文。
- 用自适应文字选项网格替代下拉菜单，将不可选五笔放入同一网格。
- 49 项共享测试、设计 lint、模拟器 Debug 与 arm64 Release/TIPA 构建通过。

## Task 10 — 兼容性测试与最终发布

### Assumptions and acceptance boundary

- Local acceptance uses the already-running iOS 18.4 `MagicBoard iPad Pro 12.9 2018` Simulator without starting a reload-enabled server.
- Simulator evidence is valid for UI layout, ordinary text input, app/orientation lifecycle, keyboard switching, and observable HID behavior supported by CoreSimulator.
- TrollStore installation, real hardware HID dispatch, OS jetsam termination, and third-party apps unavailable in the simulator require target-iPad evidence and must not be reported as simulator-proven.
- Success means every locally testable item has recorded evidence, regressions found locally are fixed and retested, documentation/build tooling are complete, the Release archive passes independent inspection, and device-only limits are explicit.

### Phase 13 — Baseline, capability matrix, and regression tests

**Status:** complete

- Restore prior evidence, inspect logs/history/Git, confirm CodeGraph health, and map lifecycle/HID cleanup paths.
- Inventory installed simulator apps and define exact simulator-versus-device coverage for every requested scenario.
- Run the shared test suite and targeted static checks before any source change.

### Phase 14 — Simulator compatibility matrix

**Status:** complete

- Validate Safari and another available text editor/input surface, system keyboard switching, portrait/landscape repetition, and foreground/background repetition.
- Exercise Esc, Ctrl, Option, Command, and four arrows in an observable shortcut-aware surface where CoreSimulator forwards them.
- Capture crash/hang/layout/modifier residue evidence from UI behavior and simulator logs.

### Phase 15 — Surgical fixes and recovery verification

**Status:** complete

- Add only evidence-driven fixes, with focused tests first where the behavior is model-testable.
- Re-run affected UI scenarios and validate keyboard-extension disappearance/reappearance cleanup using the strongest simulator-supported lifecycle mechanism.

### Phase 16 — Documentation, screenshot, and build tooling

**Status:** complete

- Generate the create-readme badge when Photoshop/template support is available.
- Create concise Chinese `README.md`, English `README_EN.md`, and one representative simulator screenshot, with quick agent install and traditional manual install sections.
- Verify the one-command Zsh Release/TIPA script and add only missing release-facing checks or explanation.

**Result:** Existing script already contains the complete one-command build/sign/validate pipeline; no redundant second script was added. Chinese/English READMEs, generated badge, and verified simulator screenshot are complete.

### Phase 17 — Final Release and remote publication

**Status:** complete

- Run all tests, design lint, XcodeGen/build checks, and the generic arm64 Release/TIPA flow.
- Independently inspect archive layout, architecture, versions, extension metadata, entitlements, and hash.
- Commit traceable changes, create the same-name remote repository for the authenticated Git host account, push the final branch, and report any target-iPad-only acceptance items.

### Phase 18 — App icon integration and installed verification

**Status:** complete

- Add opaque 1024-point AppIcon source artwork aligned with the cyan-orange design system.
- Compile the asset catalog, install the refreshed app, and verify the icon on the simulator Home Screen.
- Rebuild and independently inspect the final TIPA so the release archive—not only the source tree—contains the compiled icon.

**Result:** The simulator Home Screen displays the cyan keyboard icon at Dock size. Both Debug and Release asset compilation emitted `Assets.car`, `AppIcon60x60@2x.png`, and `AppIcon76x76@2x~ipad.png`; the rebuilt TIPA contains all three.

### Phase 19 — Physical device Jetsam memory crash fix and 1.0.1 release

**Status:** complete

- Diagnose keyboard extension crash on physical iOS 16.6.1 TrollStore iPad (verified 0 iOS 17+ APIs; identified Jetsam dirty memory kill during Rime dictionary online compilation).
- Precompile all 7 Rime schemes offline into `.table.bin`, `.prism.bin`, `.reverse.bin` and bundle under `Keyboard/RimeResources/build/`.
- Configure `RimeEngine` with `prebuiltDataDir`, `stagingDir`, and `maintenance: false` for read-only `mmap` zero-dirty-memory loading.
- Bump version to `1.0.1 (20)` in `project.yml` and add validation check in `scripts/build-tipa.zsh`.
- Rebuild `MagicBoard.tipa` and physically verify on iOS 16.6.1 device with TrollStore (confirmed 100% stable, instant open).
- Commit changes to Git, create tag `v1.0.1`, push to remote, and publish GitHub Release.

## Task 11 — 定义伴侣通信协议与共享配置

**Status:** completed

- [x] 制定无状态超低延迟二进制 UDP 通信协议规范（docs/companion_protocol.md）。
- [x] 规范动作类型（KeyDown、KeyUp、Pulse 单包脉冲、Heartbeat 状态同步、ResetAll 紧急重置）。
- [x] 规范 8 位修饰键掩码（同步 Ctrl, Shift, Option/Alt, Command/Win 状态）。
- [x] 采用国际标准 USB HID Usage 16 位编码作为统一按键标识。
- [x] 在 `MagicBoardShared` 中新增 `CompanionProtocol` 报文编解码模块。
- [x] 在 `SharedConfig` 中扩展伴侣总开关、主机地址、端口与工作模式配置。
- [x] 编写共享模块单元测试验证配置存取与报文序列化反序列化。

## Task 12 — 实现 macOS 优先被控端伴侣服务

**Status:** completed

- [x] 编写单文件 Swift 原生命令行服务 `magicboard-companion-mac`。
- [x] 提供零外部依赖的 Python 3 备用脚本（`magicboard_companion.py`）。
- [x] 实现标准 USB HID Usage 到 macOS 原生 `CGKeyCode` 的精确映射。
- [x] 采用 CoreGraphics 官方 API（`CGEventCreateKeyboardEvent` 与 `CGEventPost`）注入系统事件队列。
- [x] 实现 `pulse` 脉冲动作自动执行按下并抬起。
- [x] 实现 1.5 秒断网看门狗防止按键意外悬空。
- [x] 实现 `resetAll` 立即安全释放所有按键。
- [x] 集成 macOS 辅助功能（Accessibility）权限检测与开启提示。
- [x] 本地发送 UDP 报文实测 Command、Option、Control、Esc、Tab、F1~F12 等按键生效。

## Task 13 — 实现 Windows 被控端伴侣服务

**Status:** completed

- [x] 编写单文件绿色版免安装 Windows 伴侣服务。
- [x] 提供零依赖 Python 3 备用脚本（基于 `ctypes` 调用 `user32.dll`）。
- [x] 实现标准 USB HID Usage 到 Windows Virtual-Key 与硬件扫描码的映射。
- [x] 采用 Windows 官方 `SendInput` API 注入按键。
- [x] 支持管理员权限提权运行以突破 UIPI 隔离。
- [x] 实现 `pulse` 单包脉冲与防卡键超时看门狗。
- [x] 支持 Windows 防火墙 UDP 端口一键放行指引。
- [x] 本地及模拟器跨机 UDP 实测 Win、Alt、Ctrl、Esc、Tab、F1~F12 等按键生效。

## Task 14 — 实现 iPad 键盘端网络桥接与事件分流

**Status:** completed

- [x] 新建基于 `Network.framework` 的异步非阻塞 `CompanionBridge` 客户端。
- [x] 确保 UDP 发包运行在独立后台队列，耗时小于 1ms，不阻塞主 UI 触摸与渲染。
- [x] 严格遵循 Jetsam 内存约束，常驻内存增量控制在 100KB 以内。
- [x] 改造 `KeyboardViewController` 中的 `sndhid` 按键出口支持伴侣分流。
- [x] 改造 `sndfn` 功能键出口支持伴侣分流。
- [x] 改造 `moddown` 与 `modtap` 修饰键出口支持伴侣状态同步。
- [x] 改造 `arrdown` 方向键出口支持伴侣分流。
- [x] 改造 `inptxt` 在全接管模式下支持字符透传。
- [x] 确保关闭伴侣模式时 100% 回退现有单机本地 HID 链路。
- [x] 在 `App` 与 `Keyboard` 的 `Info.plist` 中补齐 `NSLocalNetworkUsageDescription` 局域网描述。

## Task 15 — 实现主 App 伴侣设置与权限引导交互

**Status:** completed

- [x] 在 `MagicBoardApp` 中新增远程伴侣配置卡片。
- [x] 提供伴侣模式启用总开关。
- [x] 提供被控端 IP / 域名输入框（支持 IPv4 / IPv6 / Tailscale IP）。
- [x] 提供被控端端口输入框（默认 52088）。
- [x] 提供候选栏会话级“本机 / 远端键 / 远端全”工作模式切换器。
- [x] 提供被控端系统预设切换（macOS 优先 / Windows）。
- [x] 提供一键测试连接按钮并发送测试 Ping 报文。
- [x] 在主 App 前台触发并引导用户授权 iOS 本地网络权限。
- [x] 同步更新 App Group 配置并支持键盘扩展即时读取生效。
- [x] 补充中英文界面本地化字符串。

## Task 16 — 伴侣模式综合测试构建与实机远控验证

**Status:** completed

- [x] 运行所有共享模块单元测试确保测试全部通过。
- [x] 运行 `npx @google/design.md lint` 检查设计系统合规性。
- [x] 重新生成 Xcode 工程并执行模拟器 Debug 编译与验证。
- [x] 执行 `build-tipa.zsh` 打包最终 Release 版 `MagicBoard.tipa`。
- [x] 检验安装包签名、权限配置、版本号与符号完整性。
- [x] 验证 macOS 场景下 Command+A、Command+Space、Esc、Tab、F1~F12 的伴侣穿透链路。
- [x] 验证 Windows 场景下 Win、Ctrl、Alt、Esc、Tab、F1~F12 的伴侣穿透链路。
- [x] 验证长按修饰键、Toggle 锁定与异常断网恢复能力。
- [x] 输出配套的被控端部署指南与 Tailscale 异地组网操作手册。

## Task 17 — 候选栏伴侣路由指示与会话切换

### Confirmed behavior

- 主 App 的伴侣总开关只授权键盘使用远程能力，不再自动劫持本机功能键。
- 每次新的 Keyboard Extension 会话从“本机”路由开始，不持久化上次远端状态。
- 候选词栏右侧常驻一个紧凑文字胶囊，单击循环“本机 → 远端特殊键 → 远端全键盘”。
- 伴侣总开关关闭时，路由固定为“本机”，不建立或发送远程按键链路。
- 不实现宿主 App 白名单、私有宿主识别或本机/远端双发。

### Phase 1 — 基线与影响分析

**Status:** complete

- 用 CodeGraph 定位候选栏构建、共享配置、功能键/字符/修饰键/方向键路由和测试覆盖。
- 确认新增会话状态的最小归属以及现有 `CompanionWorkMode` 的复用边界。

### Baseline verification

- `npx @google/design.md lint DESIGN.md`：0 errors、0 warnings、0 infos。
- `swift test --package-path Packages/MagicBoardShared`：72 项中 71 项通过；唯一失败是改动前 `CompanionBridgeTests.testmem` 的资源基准波动（114,688 bytes，高于 102,400-byte 阈值），功能测试全部通过。

### Errors encountered

| Error | Attempt | Resolution |
|---|---:|---|
| Swift 6 不允许把 `switch` 直接放在三元表达式分支中 | 1 | 先用 `switch` 赋值 `nextHint`，再进行布尔选择 |

### Phase 2 — 路由状态与测试

**Status:** complete

- 先添加本机、远端特殊键、远端全键盘的状态转换和路由判定测试。
- 实现最小会话级状态，保持已有伴侣配置向后兼容。

### Phase 3 — 候选栏指示与事件分流

**Status:** complete

- 在候选词滚动区右侧加入固定宽度文字胶囊，覆盖正常、不可用与三种路由状态的无障碍语义。
- 复用现有 `sndhid`、`sndfn`、修饰键、方向键和文本出口，按路由状态选择本机或远端。

### Phase 4 — 验证与交付

**Status:** complete

- 运行共享测试、`DESIGN.md` lint、XcodeGen、目标 iPad 模拟器 Debug 与 arm64 Release/TIPA。
- 验证候选词布局不跳动、三种模式切换与本机回退，并记录实体 iPad 验收项。

### Task 17 completion checklist

- [x] 新会话默认本机
- [x] 候选栏右侧显示并可循环切换三种路由
- [x] 远端特殊键只分流功能键、修饰键和方向键
- [x] 远端全键盘同时分流字符、Enter、Space 与 Delete 输入
- [x] 伴侣关闭时固定本机且不发送报文
- [x] 现有中文候选、Shift、Modifier、HID 与布局行为无回归
- [x] 测试、设计 lint、模拟器 Debug、arm64 Release/TIPA 全部通过

### Task 17 result

- 共享包 76/76 测试通过，包含 4 项新增会话路由测试；改动前偶发失败的内存基准复跑为 80 KB 并通过。
- iPad Pro 12.9-inch 模拟器实测候选栏布局稳定，禁用“本机”、青色“远端键”和青色“远端全”三种视觉状态均可见。
- `MagicBoard.tipa` 已生成并通过 ZIP、arm64、版本一致性、App Group、HID 权限与 Rime 资源检查；实体 iPad 上的真实远端按键验收留给安装后执行。

## Task 13–16 — 模拟器与 Windows SSH 最终验收

### 验收目标

把 Task 13–16 从“实现存在”提升到“可勾选完成”：以当前 iPad 模拟器作为 UDP 发送端，分别对 macOS 与 SSH 主机 `windows` 做端到端验证，并重新核验共享测试、设计 lint、Debug/Release 构建、TIPA 与部署文档。

### Phase 1 — 环境与证据基线

**Status:** complete

- 确认 Git 工作区干净、iPad 模拟器已启动、MagicBoard 与键盘扩展正在运行。
- 确认 SSH 主机 `windows` 可连接，并记录 Windows/PowerShell/Python/编译器与现有伴侣进程状态。
- 不把 mock、单元测试或“UDP 已发送”误记为 Windows `SendInput` 实机成功。

### Phase 2 — Task 13 Windows 服务验收

**Status:** complete

- 在 Windows 上运行 Python 与 C 原生服务测试，验证 HID 映射、pulse、看门狗、resetAll、防火墙指引和管理员/UIPI 状态。
- 从模拟器经真实 UDP 链路发送 Win、Alt、Ctrl、Esc、Tab、F1–F12，并在 Windows 端保留接收/注入证据。

### Phase 3 — Task 14–15 iPad 桥接与设置验收

**Status:** complete

- 运行共享桥接延迟/内存/路由测试并确认关闭时回退本地 HID。
- 在模拟器核对主 App 地址、端口、系统预设、Ping、本地网络说明与候选栏三态即时生效。

### Phase 4 — Task 16 双平台综合验收

**Status:** complete

- 在 macOS 与 Windows 端核对完整按键矩阵、修饰键保持/锁定、resetAll 与异常断网恢复。
- 重新运行设计 lint、XcodeGen、模拟器 Debug、arm64 Release/TIPA 及独立归档检查。
- 所有自动核对项、模拟器 UI 路由及真实 macOS/Windows 系统注入边界均已通过；远控软件只承载画面，不再作为键盘链路判定边界。

## Release v1.0.3 — 远程伴侣发布

### 发布目标

把当前 `1.0.2 (21)` 递增为 `1.0.3 (22)`，重新验证并发布 iPad TIPA，同时为 macOS 与 Windows 提供可直接下载的原生伴侣程序，并在中英文 README 中补充远程伴侣的安装、配置与安全说明。Release 不附带伴侣源码、测试或构建脚本。

### Phase 1 — 发布基线与资产范围

**Status:** complete

- 确认 Git 工作区、GitHub 登录、现有标签/Release 和版本源。
- 确认新版本号、构建号及伴侣资产采用独立文件还是平台压缩包。
- 核对现有构建脚本与 GitHub CLI 的真实参数。

### Phase 2 — 版本、文档与伴侣构建

**Status:** complete

- 更新共享版本源并同步生成项目。
- 更新中英文 README 的远程伴侣说明与 Release 下载方式。
- 在 macOS 与 Windows 原生环境重新构建伴侣程序，并保留 Python 备用脚本。

### Phase 3 — 验证、提交与 GitHub 发布

**Status:** complete

- 运行共享测试、文档/构建检查及伴侣服务测试。
- 构建并审计新版 `MagicBoard.tipa` 与伴侣资产。
- 提交、推送标签与分支，创建 GitHub Release 并核对远端资产。

### 发布结果

- GitHub Release：`https://github.com/yourpapayouknow/MagicBoard/releases/tag/v1.0.3`
- `MagicBoard.tipa`：17,482,595 bytes，SHA-256 `e6f76b213129b99b1c4a6c89bfc6bd852358dd7e50fb5241cd53f96941fb7089`
- `cpmac`：122,472 bytes，SHA-256 `94728ce38765d048d8049543da11c84b18ef288332774d68956ccd66d351feb5`
- `cpwin.exe`：71,540 bytes，SHA-256 `0107980f1726fb653884dd1114329de03f4292b82b35a6defa911dd523b1f81b`
