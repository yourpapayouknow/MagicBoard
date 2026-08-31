// 验证共享主题与诊断逻辑
@testable import MagicBoardShared
import Foundation
import XCTest

// 测试共享配置
final class SharedConfigTests: XCTestCase {
    // 创建隔离偏好容器
    private func mkdefs() -> (UserDefaults, String) {
        let name = "MagicBoardTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    // 验证空配置回退
    func testdflt() {
        let (defaults, name) = mkdefs()
        defer { defaults.removePersistentDomain(forName: name) }

        XCTAssertEqual(SharedConfig.ldthm(defaults: defaults), .cyanOrange)
    }

    // 验证主题往返
    func testrndtrp() {
        let (defaults, name) = mkdefs()
        defer { defaults.removePersistentDomain(forName: name) }
        let theme = BoardTheme(
            primary: ThemeColor(red: 0.2, green: 0.3, blue: 0.4),
            accent: ThemeColor(red: 0.9, green: 0.6, blue: 0.1)
        )

        SharedConfig.svthm(theme, defaults: defaults)

        XCTAssertEqual(SharedConfig.ldthm(defaults: defaults), theme)
    }

    // 验证损坏配置回退
    func testbadcfg() {
        let (defaults, name) = mkdefs()
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("bad".utf8), forKey: "magicboard.theme")

        XCTAssertEqual(SharedConfig.ldthm(defaults: defaults), .cyanOrange)
    }

    // 验证共享容器诊断
    func testdgst() {
        let (defaults, name) = mkdefs()
        defer { defaults.removePersistentDomain(forName: name) }

        XCTAssertTrue(SharedConfig.dgst(defaults: defaults).available)
    }
}
