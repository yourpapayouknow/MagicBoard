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

    // 清空全部活动修饰键
    public mutating func reset() {
        active.removeAll()
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
    private static let checkKey = "magicboard.check"

    // 读取共享主题
    public static func ldthm(defaults: UserDefaults? = UserDefaults(suiteName: groupID)) -> BoardTheme {
        guard
            let data = defaults?.data(forKey: themeKey),
            let theme = try? JSONDecoder().decode(BoardTheme.self, from: data)
        else {
            return .cyanOrange
        }
        return theme
    }

    // 保存共享主题
    public static func svthm(_ theme: BoardTheme, defaults: UserDefaults? = UserDefaults(suiteName: groupID)) {
        guard let data = try? JSONEncoder().encode(theme) else { return }
        defaults?.set(data, forKey: themeKey)
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
            ? GroupState(available: true, message: "App Group 已连接，主 App 与键盘可共享主题。")
            : GroupState(available: false, message: "App Group 无法写入，请重新安装并检查完全访问。")
    }
}
