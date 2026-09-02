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

    // 验证 Shift 按下立即启用且空松开保持
    func testshfthold() {
        var state = InputState()

        state.shftdown()
        XCTAssertTrue(state.shifted)
        state.shftup()
        XCTAssertTrue(state.shifted)
    }

    // 验证保持态再次按下松开关闭
    func testshftoff() {
        var state = InputState(shifted: true)

        state.shftdown()
        XCTAssertTrue(state.shifted)
        state.shftup()
        XCTAssertFalse(state.shifted)
    }

    // 验证按住输入期间保持且松开关闭
    func testshftused() {
        var state = InputState()

        state.shftdown()
        XCTAssertEqual(state.emit("a"), "A")
        XCTAssertTrue(state.shifted)
        XCTAssertEqual(state.emit("b"), "B")
        XCTAssertTrue(state.shifted)
        state.shftup()
        XCTAssertFalse(state.shifted)
    }

    // 验证保持态按住输入后松开关闭
    func testlockhold() {
        var state = InputState(shifted: true)

        state.shftdown()
        XCTAssertEqual(state.emit("a"), "A")
        XCTAssertTrue(state.shifted)
        state.shftup()
        XCTAssertFalse(state.shifted)
    }

    // 验证 Shift 取消恢复触摸前状态
    func testshftcncl() {
        var idle = InputState()
        idle.shftdown()
        idle.shftcncl()
        XCTAssertFalse(idle.shifted)

        var latched = InputState(shifted: true)
        latched.shftdown()
        latched.shftcncl()
        XCTAssertTrue(latched.shifted)
    }

    // 验证按住 Shift 与 Caps Lock 异或且不解锁
    func testholdcaps() {
        var state = InputState(capsLocked: true)

        state.shftdown()
        XCTAssertEqual(state.emit("a"), "a")
        XCTAssertTrue(state.shifted)
        XCTAssertTrue(state.capsLocked)
        state.shftup()
        XCTAssertFalse(state.shifted)
        XCTAssertTrue(state.capsLocked)
        XCTAssertEqual(state.emit("b"), "B")
    }

    // 验证中文替代符号跟随按住 Shift
    func testholdzhalt() {
        var state = InputState(language: .chinese)

        state.shftdown()
        XCTAssertEqual(state.emit("【", alternate: "「", letter: false), "「")
        XCTAssertTrue(state.shifted)
        state.shftup()
        XCTAssertFalse(state.shifted)
        XCTAssertEqual(state.language, .chinese)
    }

    // 验证下拖字母大写且不消费修饰状态
    func testdragltr() {
        var idle = InputState()
        XCTAssertEqual(idle.dragout("a"), "A")
        XCTAssertFalse(idle.shifted)
        XCTAssertFalse(idle.capsLocked)

        var latched = InputState(shifted: true, capsLocked: true)
        XCTAssertEqual(latched.dragout("a"), "A")
        XCTAssertTrue(latched.shifted)
        XCTAssertTrue(latched.capsLocked)
    }

    // 验证下拖双层与中文替代符号
    func testdragalt() {
        var state = InputState(language: .chinese)

        XCTAssertEqual(state.dragout("1", alternate: "!", letter: false), "!")
        XCTAssertEqual(state.dragout("【", alternate: "「", letter: false), "「")
        XCTAssertFalse(state.shifted)
        XCTAssertFalse(state.capsLocked)
        XCTAssertEqual(state.language, .chinese)
    }

    // 验证按住期间下拖输入仍在松开时关闭 Shift
    func testholddrag() {
        var state = InputState()

        state.shftdown()
        XCTAssertEqual(state.dragout("a"), "A")
        XCTAssertTrue(state.shifted)
        state.shftup()
        XCTAssertFalse(state.shifted)
    }

    // 验证 HID 组合使用后不保留单次 Shift
    func testshfthiduse() {
        var state = InputState()

        state.shftdown(.left)
        XCTAssertTrue(state.shiftHeld)
        state.shftuse()
        state.shftuse()
        XCTAssertTrue(state.shifted)
        state.shftup(.left)

        XCTAssertFalse(state.shiftHeld)
        XCTAssertFalse(state.shifted)
    }

    // 验证左右 Shift 独立释放
    func testshftpairs() {
        var state = InputState()

        state.shftdown(.left)
        state.shftdown(.right)
        state.shftuse()
        state.shftup(.left)

        XCTAssertTrue(state.shiftHeld)
        XCTAssertTrue(state.shifted)
        state.shftup(.right)
        XCTAssertFalse(state.shiftHeld)
        XCTAssertFalse(state.shifted)
    }

    // 验证左右 Shift 逐个取消恢复初始状态
    func testshftpaircncl() {
        var state = InputState()

        state.shftdown(.left)
        state.shftdown(.right)
        state.shftcncl(.left)

        XCTAssertTrue(state.shiftHeld)
        XCTAssertTrue(state.shifted)
        state.shftcncl(.right)
        XCTAssertFalse(state.shiftHeld)
        XCTAssertFalse(state.shifted)
    }

    // 验证双 Shift 空松开仍只锁定一次
    func testshftpairlock() {
        var state = InputState()

        state.shftdown(.left)
        state.shftdown(.right)
        state.shftup(.left)
        XCTAssertTrue(state.shiftHeld)
        state.shftup(.right)

        XCTAssertFalse(state.shiftHeld)
        XCTAssertTrue(state.shifted)
        XCTAssertEqual(state.emit("a"), "A")
        XCTAssertFalse(state.shifted)
    }

    // 验证修饰键默认状态
    func testmodsinit() {
        let state = ModifierState()

        XCTAssertFalse(state.isActive)
        XCTAssertFalse(state.contains(.control))
    }

    // 验证五个物理修饰键独立切换
    func testmods() {
        var state = ModifierState()
        let keys: [ModifierKey] = [.control, .leftOption, .leftCommand, .rightCommand, .rightOption]

        for key in keys {
            XCTAssertTrue(state.press(key))
            XCTAssertTrue(state.contains(key))
            XCTAssertTrue(state.isActive)
            XCTAssertTrue(state.release(key))
            XCTAssertFalse(state.contains(key))
            XCTAssertFalse(state.isActive)
        }
    }

    // 验证重复修饰事件保持幂等
    func testmodsdup() {
        var state = ModifierState()

        XCTAssertTrue(state.press(.control))
        XCTAssertFalse(state.press(.control))
        XCTAssertTrue(state.release(.control))
        XCTAssertFalse(state.release(.control))
        XCTAssertFalse(state.isActive)
    }

    // 验证左右同类修饰键互不释放
    func testmodpairs() {
        var state = ModifierState()

        state.press(.leftCommand)
        state.press(.rightCommand)
        XCTAssertTrue(state.release(.leftCommand))
        XCTAssertFalse(state.contains(.leftCommand))
        XCTAssertTrue(state.contains(.rightCommand))
        XCTAssertTrue(state.isActive)
    }

    // 验证一次清理全部修饰键
    func testmodsrst() {
        var state = ModifierState()

        state.press(.control)
        state.press(.leftOption)
        state.tap(.leftOption)
        state.press(.rightCommand)
        state.reset()

        XCTAssertFalse(state.isActive)
        XCTAssertFalse(state.contains(.control))
        XCTAssertFalse(state.contains(.leftOption))
        XCTAssertFalse(state.contains(.rightCommand))
    }

    // 验证单击修饰键进入一次性锁定
    func testmodstick() {
        var state = ModifierState()

        XCTAssertTrue(state.press(.control))
        XCTAssertTrue(state.tap(.control))
        XCTAssertTrue(state.isSticky(.control))
        XCTAssertTrue(state.contains(.control))
        XCTAssertEqual(state.consume(), [.control])
        XCTAssertFalse(state.isActive)
    }

    // 验证再次单击已锁定修饰键会解除
    func testmoduntgl() {
        var state = ModifierState()

        state.press(.leftOption)
        XCTAssertTrue(state.tap(.leftOption))
        XCTAssertTrue(state.press(.leftOption))
        XCTAssertFalse(state.tap(.leftOption))
        XCTAssertFalse(state.isActive)
    }

    // 验证多个锁定修饰键由同一有效键消费
    func testmodcombo() {
        var state = ModifierState()

        state.press(.control)
        state.tap(.control)
        state.press(.leftCommand)
        state.tap(.leftCommand)

        XCTAssertEqual(state.consume(), [.control, .leftCommand])
        XCTAssertFalse(state.isActive)
    }

    // 验证参与组合键的物理按住不会转为锁定
    func testmodheld() {
        var state = ModifierState()

        state.press(.rightOption)
        state.use()

        XCTAssertFalse(state.tap(.rightOption))
        XCTAssertFalse(state.isSticky(.rightOption))
        XCTAssertFalse(state.isActive)
    }

    // 验证取消触摸恢复原有锁定状态
    func testmodcncl() {
        var state = ModifierState()

        state.press(.control)
        XCTAssertFalse(state.cancel(.control))

        state.press(.rightCommand)
        state.tap(.rightCommand)
        state.press(.rightCommand)
        XCTAssertTrue(state.cancel(.rightCommand))
        XCTAssertTrue(state.isSticky(.rightCommand))
    }

    // 验证消费时保留仍被手指按住的修饰键
    func testmodkeep() {
        var state = ModifierState()

        state.press(.leftCommand)
        state.tap(.leftCommand)
        state.press(.leftCommand)

        XCTAssertEqual(state.consume(), [])
        XCTAssertTrue(state.contains(.leftCommand))
        XCTAssertFalse(state.isSticky(.leftCommand))
        XCTAssertFalse(state.tap(.leftCommand))
    }

    // 验证未越过阈值时保留位移
    func testcursres() {
        var motion = CursorMotion(step: 12)

        XCTAssertEqual(motion.move(x: 7, y: 1), [])
        XCTAssertEqual(motion.move(x: 5, y: 0), [.right])
        XCTAssertEqual(motion.move(x: 11, y: 0), [])
        XCTAssertEqual(motion.move(x: 1, y: 0), [.right])
    }

    // 验证四方向与多步移动
    func testcursdirs() {
        var motion = CursorMotion(step: 12)

        XCTAssertEqual(motion.move(x: -25, y: 2), [.left, .left])
        XCTAssertEqual(motion.move(x: 1, y: -24), [.up, .up])
        XCTAssertEqual(motion.move(x: 0, y: 36), [.down, .down, .down])
        XCTAssertEqual(motion.move(x: 12, y: 0), [.right])
    }

    // 验证主轴选择避免斜向双触发
    func testcursaxis() {
        var motion = CursorMotion(step: 12)

        XCTAssertEqual(motion.move(x: 13, y: 12), [.right])
        XCTAssertEqual(motion.move(x: 11, y: -13), [.up])
    }

    // 验证反向移动丢弃旧方向余量
    func testcursrev() {
        var motion = CursorMotion(step: 12)

        XCTAssertEqual(motion.move(x: 10, y: 0), [])
        XCTAssertEqual(motion.move(x: -3, y: 0), [])
        XCTAssertEqual(motion.move(x: -9, y: 0), [.left])
    }

    // 验证复位清除所有残余位移
    func testcursrst() {
        var motion = CursorMotion(step: 12)

        XCTAssertEqual(motion.move(x: 10, y: -8), [])
        motion.reset()
        XCTAssertEqual(motion.move(x: 2, y: -4), [])
    }
}
