// 管理 MagicBoard 离线 Rime 输入会话
import Foundation
import LibrimeKit
import MagicBoardShared

// 保存一次输入后的候选快照
struct IMESnapshot {
    let rawInput: String
    let preedit: String
    let candidates: [String]
    let commit: String
    let composing: Bool
}

// 串行管理进程内唯一 librime 会话
@MainActor
final class RimeEngine {
    static let shared = RimeEngine()

    private(set) var ready = false
    private var scheme: ChineseScheme?
    private var started = false

    // 限制外部创建重复会话
    private init() {}

    // 初始化共享资源与用户数据目录
    @discardableResult
    func start(scheme: ChineseScheme) -> Bool {
        if started { return setScheme(scheme) }
        guard
            let sharedDir = Bundle.main.resourceURL?.appendingPathComponent("RimeResources", isDirectory: true),
            FileManager.default.fileExists(atPath: sharedDir.path),
            let userDir = makeUserDir()
        else { return false }

        let traits = Rime.createTraits(sharedSupportDir: sharedDir.path, userDataDir: userDir.path)
        let prebuilt = sharedDir.appendingPathComponent("build", isDirectory: true)
        if FileManager.default.fileExists(atPath: prebuilt.path) {
            traits.prebuiltDataDir = prebuilt.path
        }
        let staging = userDir.appendingPathComponent("build", isDirectory: true)
        traits.stagingDir = staging.path
        traits.minLogLevel = 3
        Rime.shared.start(traits, maintenance: false, fullCheck: false)
        started = true
        guard validateResources() else {
            ready = false
            return false
        }
        return setScheme(scheme)
    }

    // 切换全拼或双拼方案
    @discardableResult
    func setScheme(_ value: ChineseScheme) -> Bool {
        if scheme == value, ready { return true }
        if Rime.shared.isRunning() { Rime.shared.cleanComposition() }
        ready = Rime.shared.setSchema(value.schemaID)
        if ready { scheme = value }
        return ready
    }

    // 向 Rime 输入单个可打印字符
    func input(_ value: String) -> IMESnapshot? {
        guard ready, Rime.shared.inputKey(value) else { return nil }
        return snapshot()
    }

    // 向 Rime 输入 X11 控制键
    func command(_ keyCode: Int32) -> IMESnapshot? {
        guard ready, Rime.shared.inputKeyCode(keyCode) else { return nil }
        return snapshot()
    }

    // 选择全部候选中的指定候选词
    func select(_ index: Int) -> IMESnapshot? {
        guard ready else { return nil }
        let menu = Rime.shared.context().menu
        guard let position = CandidatePosition(globalIndex: index, pageSize: Int(menu?.pageSize ?? 0)) else {
            return nil
        }
        var currentPage = Int(menu?.pageNo ?? 0)
        while currentPage < position.page {
            guard Rime.shared.changePage(backward: false) else { return nil }
            currentPage += 1
        }
        while currentPage > position.page {
            guard Rime.shared.changePage(backward: true) else { return nil }
            currentPage -= 1
        }
        guard Rime.shared.selectCandidateOnCurrentPage(index: position.index) else { return nil }
        return snapshot()
    }

    // 提交当前组合文本
    func commit() -> IMESnapshot? {
        guard ready, Rime.shared.commitComposition() else { return nil }
        return snapshot()
    }

    // 清空当前组合文本
    func reset() {
        guard ready else { return }
        Rime.shared.cleanComposition()
    }

    // 判断当前是否存在未提交组合
    var isComposing: Bool {
        ready && Rime.shared.status().isComposing
    }

    // 获取当前候选状态
    func snapshot() -> IMESnapshot {
        let status = Rime.shared.status()
        let context = Rime.shared.context()
        return IMESnapshot(
            rawInput: Rime.shared.getInputKeys(),
            preedit: context.composition?.preedit ?? Rime.shared.getInputKeys(),
            candidates: Rime.shared.candidateList().map(\.text),
            commit: Rime.shared.getCommitText(),
            composing: status.isComposing
        )
    }

    // 用全拼候选验证词典、棱镜与 OpenCC 资源
    private func validateResources() -> Bool {
        guard Rime.shared.setSchema(ChineseScheme.fullPinyin.schemaID) else { return false }
        for character in "nihao" {
            guard Rime.shared.inputKey(String(character)) else {
                Rime.shared.cleanComposition()
                return false
            }
        }
        let valid = !Rime.shared.candidateList().isEmpty
        Rime.shared.cleanComposition()
        return valid
    }

    // 创建 App Group 或扩展本地用户数据目录
    private func makeUserDir() -> URL? {
        let manager = FileManager.default
        let base = manager.containerURL(forSecurityApplicationGroupIdentifier: SharedConfig.groupID)
            ?? manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let directory = base?.appendingPathComponent("Rime", isDirectory: true) else { return nil }
        do {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        } catch {
            return nil
        }
    }
}
