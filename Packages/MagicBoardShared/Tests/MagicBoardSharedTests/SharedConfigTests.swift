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

    // 验证单次 Shift 消费
    func testshft() {
        var state = InputState()
        state.tglshft()

        XCTAssertEqual(state.emit("a"), "A")
        XCTAssertFalse(state.shifted)
        XCTAssertEqual(state.emit("b"), "b")
    }

    // 验证 Caps Lock 持续
    func testcaps() {
        var state = InputState()
        state.tglcaps()

        XCTAssertEqual(state.emit("a"), "A")
        XCTAssertEqual(state.emit("b"), "B")
        XCTAssertTrue(state.capsLocked)
    }

    // 验证 Caps Lock 与 Shift 异或
    func testcapshft() {
        var state = InputState(capsLocked: true)
        state.tglshft()

        XCTAssertEqual(state.emit("a"), "a")
        XCTAssertEqual(state.emit("b"), "B")
        XCTAssertTrue(state.capsLocked)
    }

    // 验证 Shift 替代字符
    func testshftalt() {
        var state = InputState(shifted: true)

        XCTAssertEqual(state.emit("1", alternate: "!", letter: false), "!")
        XCTAssertFalse(state.shifted)
        XCTAssertEqual(state.emit("2", alternate: "@", letter: false), "2")
    }

    // 验证语言切换保留大小写状态
    func testlang() {
        var state = InputState(shifted: true, capsLocked: true)

        state.tgllang()

        XCTAssertEqual(state.language, .chinese)
        XCTAssertTrue(state.shifted)
        XCTAssertTrue(state.capsLocked)
        state.tgllang()
        XCTAssertEqual(state.language, .english)
    }

    // 验证 Caps Lock 保留单次 Shift
    func testcapskeep() {
        var state = InputState(shifted: true)

        state.tglcaps()

        XCTAssertTrue(state.capsLocked)
        XCTAssertTrue(state.shifted)
        XCTAssertEqual(state.emit("a"), "a")
    }
}
