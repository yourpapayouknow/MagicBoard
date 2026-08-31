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
