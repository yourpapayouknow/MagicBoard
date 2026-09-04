// 管理 App Group 共享主题
import Foundation

// 表示跨界面颜色
public struct ThemeColor: Codable, Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    // 创建共享颜色
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

// 表示共享主题
public struct BoardTheme: Codable, Equatable, Sendable {
    public let primary: ThemeColor
    public let accent: ThemeColor

    // 创建共享主题
    public init(primary: ThemeColor, accent: ThemeColor) {
        self.primary = primary
        self.accent = accent
    }

    public static let cyanOrange = BoardTheme(
        primary: ThemeColor(red: 0, green: 0.72, blue: 0.82),
        accent: ThemeColor(red: 1, green: 0.49, blue: 0)
    )
}

// 定义主应用与键盘共享的外观模式
public enum AppearanceMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case light
    case dark
    case custom

    public var id: String { rawValue }

    // 返回外观模式名称
    public var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        case .custom: "自定义"
        }
    }
}

// 定义中文输入方案
public enum ChineseScheme: String, CaseIterable, Codable, Identifiable, Sendable {
    case fullPinyin
    case microsoft
    case naturalCode
    case intelligentABC
    case xiaohe
    case pinyinJiajia
    case sitong

    public var id: String { rawValue }

    // 返回输入方案名称
    public var title: String {
        switch self {
        case .fullPinyin: "全拼"
        case .microsoft: "微软双拼"
        case .naturalCode: "自然码双拼"
        case .intelligentABC: "智能 ABC 双拼"
        case .xiaohe: "小鹤双拼"
        case .pinyinJiajia: "拼音加加双拼"
        case .sitong: "四通双拼"
        }
    }

    // 返回 Rime 方案标识
    public var schemaID: String {
        switch self {
        case .fullPinyin: "luna_pinyin_simp"
        case .microsoft: "double_pinyin_mspy"
        case .naturalCode: "double_pinyin"
        case .intelligentABC: "double_pinyin_abc"
        case .xiaohe: "double_pinyin_flypy"
        case .pinyinJiajia: "double_pinyin_pyjj"
        case .sitong: "double_pinyin_st"
        }
    }
}

// 定义修饰键操作模式
public enum ModifierMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case hold
    case toggle
    case mixed

    public var id: String { rawValue }

    // 返回修饰键模式名称
    public var title: String {
        switch self {
        case .hold: "按住"
        case .toggle: "切换"
        case .mixed: "混合"
        }
    }
}

// 定义伴侣工作模式
public enum CompanionWorkMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case onlyFunctions
    case fullKeyboard

    public var id: String { rawValue }

    // 返回工作模式名称
    public var title: String {
        switch self {
        case .onlyFunctions: "仅功能键分流"
        case .fullKeyboard: "全键盘接管"
        }
    }
}

// 定义伴侣目标操作系统
public enum CompanionTargetOS: String, CaseIterable, Codable, Identifiable, Sendable {
    case macOS
    case windows

    public var id: String { rawValue }

    // 返回操作系统名称
    public var title: String {
        switch self {
        case .macOS: "macOS"
        case .windows: "Windows"
        }
    }
}

// 保存伴侣远程通信配置
public struct CompanionConfig: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var host: String
    public var port: UInt16
    public var workMode: CompanionWorkMode
    public var targetOS: CompanionTargetOS
    public var pulseDurationMs: UInt16

    // 创建伴侣配置
    public init(
        enabled: Bool = false,
        host: String = "127.0.0.1",
        port: UInt16 = 52088,
        workMode: CompanionWorkMode = .onlyFunctions,
        targetOS: CompanionTargetOS = .macOS,
        pulseDurationMs: UInt16 = 20
    ) {
        self.enabled = enabled
        self.host = host
        self.port = port
        self.workMode = workMode
        self.targetOS = targetOS
        self.pulseDurationMs = pulseDurationMs
    }

    public static let standard = CompanionConfig()

    // 限制伴侣参数到安全范围
    fileprivate func norm() -> CompanionConfig {
        CompanionConfig(
            enabled: enabled,
            host: host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: port == 0 ? 52088 : port,
            workMode: workMode,
            targetOS: targetOS,
            pulseDurationMs: min(500, max(5, pulseDurationMs))
        )
    }
}

// 保存键盘布局参数
public struct LayoutConfig: Codable, Equatable, Sendable {
    public var height: Double
    public var horizontalGap: Double
    public var verticalGap: Double
    public var outerInset: Double

    // 创建布局参数
    public init(height: Double, horizontalGap: Double, verticalGap: Double, outerInset: Double) {
        self.height = height
        self.horizontalGap = horizontalGap
        self.verticalGap = verticalGap
        self.outerInset = outerInset
    }

    public static let standard = LayoutConfig(height: 430, horizontalGap: 6, verticalGap: 7, outerInset: 7)

    // 限制布局参数到安全范围
    fileprivate func norm() -> LayoutConfig {
        LayoutConfig(
            height: height.clmp(340 ... 430),
            horizontalGap: horizontalGap.clmp(3 ... 9),
            verticalGap: verticalGap.clmp(4 ... 12),
            outerInset: outerInset.clmp(4 ... 16)
        )
    }
}

// 保存键盘外观参数
public struct AppearanceConfig: Codable, Equatable, Sendable {
    public var mode: AppearanceMode
    public var accent: ThemeColor
    public var board: ThemeColor
    public var key: ThemeColor
    public var text: ThemeColor

    // 创建外观参数
    public init(mode: AppearanceMode, accent: ThemeColor, board: ThemeColor, key: ThemeColor, text: ThemeColor) {
        self.mode = mode
        self.accent = accent
        self.board = board
        self.key = key
        self.text = text
    }

    public static let standard = AppearanceConfig(
        mode: .system,
        accent: BoardTheme.cyanOrange.primary,
        board: ThemeColor(red: 0.78, green: 0.8, blue: 0.84),
        key: ThemeColor(red: 0.98, green: 0.98, blue: 1),
        text: ThemeColor(red: 0.08, green: 0.08, blue: 0.1)
    )

    // 限制自定义颜色到有效范围
    fileprivate func norm() -> AppearanceConfig {
        AppearanceConfig(
            mode: mode,
            accent: accent.norm(),
            board: board.norm(),
            key: key.norm(),
            text: text.norm()
        )
    }
}

// 保存主应用与键盘共享的完整设置
public struct BoardSettings: Codable, Equatable, Sendable {
    public var version: Int
    public var chineseEnabled: Bool
    public var scheme: ChineseScheme
    public var layout: LayoutConfig
    public var appearance: AppearanceConfig
    public var keySound: Bool
    public var simulatedHaptics: Bool
    public var hapticIntensity: Double
    public var stickyModifiers: Bool
    public var modifierMode: ModifierMode
    public var companion: CompanionConfig

    // 创建完整设置
    public init(
        version: Int = 1,
        chineseEnabled: Bool = true,
        scheme: ChineseScheme = .fullPinyin,
        layout: LayoutConfig = .standard,
        appearance: AppearanceConfig = .standard,
        keySound: Bool = true,
        simulatedHaptics: Bool = false,
        hapticIntensity: Double = 0.6,
        stickyModifiers: Bool = true,
        modifierMode: ModifierMode = .mixed,
        companion: CompanionConfig = .standard
    ) {
        self.version = version
        self.chineseEnabled = chineseEnabled
        self.scheme = scheme
        self.layout = layout
        self.appearance = appearance
        self.keySound = keySound
        self.simulatedHaptics = simulatedHaptics
        self.hapticIntensity = hapticIntensity
        self.stickyModifiers = stickyModifiers
        self.modifierMode = modifierMode
        self.companion = companion
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case chineseEnabled
        case scheme
        case layout
        case appearance
        case keySound
        case simulatedHaptics
        case hapticIntensity
        case stickyModifiers
        case modifierMode
        case companion
    }

    // 解码旧设置并默认开启中文输入与伴侣默认配置
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        chineseEnabled = try values.decodeIfPresent(Bool.self, forKey: .chineseEnabled) ?? true
        scheme = try values.decode(ChineseScheme.self, forKey: .scheme)
        layout = try values.decode(LayoutConfig.self, forKey: .layout)
        appearance = try values.decode(AppearanceConfig.self, forKey: .appearance)
        keySound = try values.decode(Bool.self, forKey: .keySound)
        simulatedHaptics = try values.decode(Bool.self, forKey: .simulatedHaptics)
        hapticIntensity = try values.decodeIfPresent(Double.self, forKey: .hapticIntensity) ?? 0.6
        stickyModifiers = try values.decode(Bool.self, forKey: .stickyModifiers)
        modifierMode = try values.decode(ModifierMode.self, forKey: .modifierMode)
        companion = try values.decodeIfPresent(CompanionConfig.self, forKey: .companion) ?? .standard
    }

    public static let standard = BoardSettings()

    // 生成安全的当前版本设置
    fileprivate func norm() -> BoardSettings {
        BoardSettings(
            version: 1,
            chineseEnabled: chineseEnabled,
            scheme: scheme,
            layout: layout.norm(),
            appearance: appearance.norm(),
            keySound: keySound,
            simulatedHaptics: simulatedHaptics,
            hapticIntensity: min(1.0, max(0.1, hapticIntensity)),
            stickyModifiers: stickyModifiers,
            modifierMode: modifierMode,
            companion: companion.norm()
        )
    }
}

// 表示键盘扩展最近状态
public struct KeyboardReport: Codable, Equatable, Sendable {
    public let lastSeen: Date
    public let hasFullAccess: Bool
    public let engineReady: Bool
    public let scheme: ChineseScheme

    // 创建键盘扩展状态
    public init(lastSeen: Date, hasFullAccess: Bool, engineReady: Bool, scheme: ChineseScheme) {
        self.lastSeen = lastSeen
        self.hasFullAccess = hasFullAccess
        self.engineReady = engineReady
        self.scheme = scheme
    }
}

// 表示当前输入语言
public enum BoardLang: Equatable, Sendable {
    case english
    case chinese
}

// 标识左右物理 Shift
public enum ShiftKey: Hashable, Sendable {
    case left
    case right
}

// 标识底部物理修饰键
public enum ModifierKey: Hashable, Sendable {
    case control
    case leftOption
    case leftCommand
    case rightCommand
    case rightOption
}

// 管理全部按住的物理修饰键
public struct ModifierState: Equatable, Sendable {
    private var active: Set<ModifierKey>

    // 创建空修饰键状态
    public init() {
        active = []
    }

    // 判断是否存在活动修饰键
    public var isActive: Bool {
        !active.isEmpty
    }

    // 判断指定修饰键是否活动
    public func contains(_ key: ModifierKey) -> Bool {
        active.contains(key)
    }

    // 记录修饰键按下并返回是否改变
    @discardableResult
    public mutating func press(_ key: ModifierKey) -> Bool {
        active.insert(key).inserted
    }

    // 记录修饰键释放并返回是否改变
    @discardableResult
    public mutating func release(_ key: ModifierKey) -> Bool {
        active.remove(key) != nil
    }

    // 完成修饰键单击并立即释放
    @discardableResult
    public mutating func tap(_ key: ModifierKey) -> Bool {
        release(key)
    }

    // 清空全部活动修饰键
    public mutating func reset() {
        active.removeAll()
    }
}

// 表示 Sticky Modifier 的保持阶段
public enum ModifierStage: Equatable, Sendable {
    case inactive
    case once
    case locked
}

// 指示修饰键抬起后的 HID 处理
public enum ModifierTapAction: Equatable, Sendable {
    case release
    case keepOnce
    case keepLocked
}

// 管理修饰键单次保持与双击锁定
public struct ModifierLatchState: Equatable, Sendable {
    private var once: Set<ModifierKey> = []
    private var locked: Set<ModifierKey> = []
    private var lastTap: [ModifierKey: Double] = [:]

    // 创建空保持状态
    public init() {}

    // 返回指定修饰键的保持阶段
    public func stage(_ key: ModifierKey) -> ModifierStage {
        if locked.contains(key) { return .locked }
        if once.contains(key) { return .once }
        return .inactive
    }

    // 处理一次修饰键抬起
    public mutating func tap(
        _ key: ModifierKey,
        sticky: Bool,
        mode: ModifierMode,
        heldFor: Double,
        at time: Double
    ) -> ModifierTapAction {
        guard sticky, mode != .hold, mode == .toggle || heldFor < 0.32 else {
            clear(key)
            return .release
        }
        if locked.remove(key) != nil {
            lastTap[key] = nil
            return .release
        }
        if mode == .toggle {
            once.remove(key)
            locked.insert(key)
            lastTap[key] = nil
            return .keepLocked
        }
        if once.contains(key), time - (lastTap[key] ?? -.infinity) <= 0.32 {
            once.remove(key)
            locked.insert(key)
            lastTap[key] = nil
            return .keepLocked
        }
        once.insert(key)
        lastTap[key] = time
        return .keepOnce
    }

    // 消费并返回全部单次保持键
    public mutating func consumeOnce() -> Set<ModifierKey> {
        let consumed = once
        once.removeAll()
        for key in consumed { lastTap[key] = nil }
        return consumed
    }

    // 清空全部保持状态
    public mutating func reset() {
        once.removeAll()
        locked.removeAll()
        lastTap.removeAll()
    }

    // 清除指定修饰键状态
    private mutating func clear(_ key: ModifierKey) {
        once.remove(key)
        locked.remove(key)
        lastTap[key] = nil
    }
}

// 管理语言与大小写状态
public struct InputState: Equatable, Sendable {
    public private(set) var language: BoardLang
    public private(set) var shifted: Bool
    public private(set) var capsLocked: Bool
    private var shiftkeys: Set<ShiftKey>
    private var shftstart: Bool
    private var shftused: Bool

    // 创建默认输入状态
    public init(
        language: BoardLang = .english,
        shifted: Bool = false,
        capsLocked: Bool = false
    ) {
        self.language = language
        self.shifted = shifted
        self.capsLocked = capsLocked
        shiftkeys = []
        shftstart = false
        shftused = false
    }

    // 判断字母输出大小写
    public var uppercase: Bool {
        shifted != capsLocked
    }

    // 判断是否按住任一 Shift
    public var shiftHeld: Bool {
        !shiftkeys.isEmpty
    }

    // 切换单次 Shift
    public mutating func tglshft() {
        shifted.toggle()
    }

    // 开始 Shift 触摸
    public mutating func shftdown(_ key: ShiftKey = .left) {
        guard shiftkeys.insert(key).inserted else { return }
        guard shiftkeys.count == 1 else {
            shifted = true
            return
        }
        shftstart = shifted
        shftused = false
        shifted = true
    }

    // 完成 Shift 触摸
    public mutating func shftup(_ key: ShiftKey = .left) {
        guard shiftkeys.remove(key) != nil else { return }
        guard shiftkeys.isEmpty else { return }
        shifted = !shftstart && !shftused
        rstshft()
    }

    // 取消 Shift 触摸
    public mutating func shftcncl(_ key: ShiftKey? = nil) {
        guard shiftHeld else { return }
        if let key {
            shiftkeys.remove(key)
        } else {
            shiftkeys.removeAll()
        }
        guard shiftkeys.isEmpty else { return }
        shifted = shftstart
        rstshft()
    }

    // 标记 Shift 已用于组合键
    public mutating func shftuse() {
        if shiftHeld { shftused = true }
    }

    // 消费功能层动作使用的 Shift
    public mutating func usefn() {
        if shiftHeld {
            shftuse()
        } else {
            shifted = false
        }
    }

    // 切换 Caps Lock
    public mutating func tglcaps() {
        capsLocked.toggle()
    }

    // 切换输入语言
    public mutating func tgllang() {
        language = language == .english ? .chinese : .english
    }

    // 生成字符并消费 Shift
    public mutating func emit(
        _ value: String,
        alternate: String? = nil,
        letter: Bool = true
    ) -> String {
        let output: String
        if letter {
            output = uppercase ? value.uppercased() : value.lowercased()
        } else {
            output = shifted ? (alternate ?? value) : value
        }
        if shiftHeld {
            shftuse()
        } else {
            shifted = false
        }
        return output
    }

    // 生成下拖替代字符
    public mutating func dragout(
        _ value: String,
        alternate: String? = nil,
        letter: Bool = true
    ) -> String {
        shftuse()
        return letter ? value.uppercased() : (alternate ?? value)
    }

    // 清理 Shift 触摸记录
    private mutating func rstshft() {
        shiftkeys.removeAll()
        shftstart = false
        shftused = false
    }
}

// 标识光标移动方向
public enum CursorDirection: Equatable, Sendable {
    case left
    case right
    case up
    case down
}

// 将触控板位移转换为离散方向步进
public struct CursorMotion: Equatable, Sendable {
    public let step: Double
    private var residualX: Double
    private var residualY: Double

    // 创建指定步长的光标位移器
    public init(step: Double) {
        precondition(step > 0)
        self.step = step
        residualX = 0
        residualY = 0
    }

    // 消费主轴位移并返回方向步进
    public mutating func move(x: Double, y: Double) -> [CursorDirection] {
        if abs(x) >= abs(y) {
            residualY = 0
            let result = Self.steps(
                delta: x,
                residual: residualX,
                step: step,
                negative: .left,
                positive: .right
            )
            residualX = result.residual
            return result.directions
        }

        residualX = 0
        let result = Self.steps(
            delta: y,
            residual: residualY,
            step: step,
            negative: .up,
            positive: .down
        )
        residualY = result.residual
        return result.directions
    }

    // 清除未完成的方向位移
    public mutating func reset() {
        residualX = 0
        residualY = 0
    }

    // 计算单轴完整步数与剩余位移
    private static func steps(
        delta: Double,
        residual: Double,
        step: Double,
        negative: CursorDirection,
        positive: CursorDirection
    ) -> (directions: [CursorDirection], residual: Double) {
        var total = residual
        if total != 0, delta != 0, total.sign != delta.sign {
            total = 0
        }
        total += delta

        let count = Int(abs(total) / step)
        guard count > 0 else { return ([], total) }

        let direction = total < 0 ? negative : positive
        let consumed = Double(count) * step * (total < 0 ? -1 : 1)
        return (Array(repeating: direction, count: count), total - consumed)
    }
}

// 表示共享容器诊断
public struct GroupState: Equatable, Sendable {
    public let available: Bool
    public let message: String

    // 创建诊断状态
    public init(available: Bool, message: String) {
        self.available = available
        self.message = message
    }
}

// 读写共享配置
public enum SharedConfig {
    public static let groupID = "group.com.iwmei.magicboard"
    private static let themeKey = "magicboard.theme"
    private static let settingsKey = "magicboard.settings.v1"
    private static let reportKey = "magicboard.keyboard.report"
    private static let checkKey = "magicboard.check"

    // 读取完整共享设置
    public static func ldcfg(defaults: UserDefaults? = UserDefaults(suiteName: groupID)) -> BoardSettings {
        guard let defaults else { return .standard }
        if
            let data = defaults.data(forKey: settingsKey),
            let settings = try? JSONDecoder().decode(BoardSettings.self, from: data)
        {
            return settings.norm()
        }

        var settings = BoardSettings.standard
        if let theme = rawthm(defaults: defaults) {
            settings.appearance.accent = theme.primary
        }
        return settings
    }

    // 保存完整共享设置
    public static func svcfg(_ settings: BoardSettings, defaults: UserDefaults? = UserDefaults(suiteName: groupID)) {
        guard let defaults else { return }
        let normalized = settings.norm()
        guard let data = try? JSONEncoder().encode(normalized) else { return }
        defaults.set(data, forKey: settingsKey)
        svthm(
            BoardTheme(primary: normalized.appearance.accent, accent: BoardTheme.cyanOrange.accent),
            defaults: defaults
        )
    }

    // 读取共享主题
    public static func ldthm(defaults: UserDefaults? = UserDefaults(suiteName: groupID)) -> BoardTheme {
        if
            let data = defaults?.data(forKey: settingsKey),
            let settings = try? JSONDecoder().decode(BoardSettings.self, from: data)
        {
            return BoardTheme(
                primary: settings.norm().appearance.accent,
                accent: BoardTheme.cyanOrange.accent
            )
        }
        return defaults.flatMap(rawthm) ?? .cyanOrange
    }

    // 保存共享主题
    public static func svthm(_ theme: BoardTheme, defaults: UserDefaults? = UserDefaults(suiteName: groupID)) {
        guard let data = try? JSONEncoder().encode(theme) else { return }
        defaults?.set(data, forKey: themeKey)
    }

    // 读取键盘扩展最近状态
    public static func ldrpt(defaults: UserDefaults? = UserDefaults(suiteName: groupID)) -> KeyboardReport? {
        guard
            let data = defaults?.data(forKey: reportKey),
            let report = try? JSONDecoder().decode(KeyboardReport.self, from: data)
        else { return nil }
        return report
    }

    // 保存键盘扩展最近状态
    public static func svrpt(_ report: KeyboardReport, defaults: UserDefaults? = UserDefaults(suiteName: groupID)) {
        guard let data = try? JSONEncoder().encode(report) else { return }
        defaults?.set(data, forKey: reportKey)
    }

    // 检查共享容器
    public static func dgst(defaults: UserDefaults? = UserDefaults(suiteName: groupID)) -> GroupState {
        guard let defaults else {
            return GroupState(available: false, message: "App Group 不可用，请检查 TrollStore entitlement。")
        }

        let token = UUID().uuidString
        defaults.set(token, forKey: checkKey)
        let available = defaults.string(forKey: checkKey) == token
        defaults.removeObject(forKey: checkKey)

        return available
            ? GroupState(available: true, message: "App Group 已连接，主 App 与键盘可共享设置。")
            : GroupState(available: false, message: "App Group 无法写入，请重新安装并检查完全访问。")
    }

    // 解码旧版共享主题
    private static func rawthm(defaults: UserDefaults) -> BoardTheme? {
        guard let data = defaults.data(forKey: themeKey) else { return nil }
        return try? JSONDecoder().decode(BoardTheme.self, from: data)
    }
}

// 提供数值安全限制
private extension Double {
    // 限制数值到闭区间
    func clmp(_ range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// 提供颜色安全限制
private extension ThemeColor {
    // 限制颜色通道到有效范围
    func norm() -> ThemeColor {
        ThemeColor(
            red: red.clmp(0 ... 1),
            green: green.clmp(0 ... 1),
            blue: blue.clmp(0 ... 1),
            alpha: alpha.clmp(0 ... 1)
        )
    }
}
