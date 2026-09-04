// 验证伴侣通信协议（MBCP）报文编解码与修饰键掩码
@testable import MagicBoardShared
import Foundation
import XCTest

// 测试伴侣通信协议
final class CompanionProtocolTests: XCTestCase {
    // 验证协议魔数、版本与定长常量
    func testConstants() {
        XCTAssertEqual(CompanionPacket.magic, 0x4D424350) // ASCII "MBCP"
        XCTAssertEqual(CompanionPacket.currentVersion, 1)
        XCTAssertEqual(CompanionPacket.packetLength, 16)
    }

    // 验证动作类型枚举编码与字符串转换
    func testActionValues() {
        XCTAssertEqual(CompanionAction.keyDown.rawValue, 0x01)
        XCTAssertEqual(CompanionAction.keyUp.rawValue, 0x02)
        XCTAssertEqual(CompanionAction.pulse.rawValue, 0x03)
        XCTAssertEqual(CompanionAction.heartbeat.rawValue, 0x04)
        XCTAssertEqual(CompanionAction.resetAll.rawValue, 0x05)

        XCTAssertEqual(CompanionAction.keyDown.description, "keyDown")
        XCTAssertEqual(CompanionAction.keyUp.description, "keyUp")
        XCTAssertEqual(CompanionAction.pulse.description, "pulse")
        XCTAssertEqual(CompanionAction.heartbeat.description, "heartbeat")
        XCTAssertEqual(CompanionAction.resetAll.description, "resetAll")
    }

    // 验证 8 位修饰键掩码位图
    func testModifierMasks() {
        XCTAssertEqual(CompanionModifiers.leftControl.rawValue, 0x01)
        XCTAssertEqual(CompanionModifiers.leftShift.rawValue, 0x02)
        XCTAssertEqual(CompanionModifiers.leftOption.rawValue, 0x04)
        XCTAssertEqual(CompanionModifiers.leftCommand.rawValue, 0x08)
        XCTAssertEqual(CompanionModifiers.rightControl.rawValue, 0x10)
        XCTAssertEqual(CompanionModifiers.rightShift.rawValue, 0x20)
        XCTAssertEqual(CompanionModifiers.rightOption.rawValue, 0x40)
        XCTAssertEqual(CompanionModifiers.rightCommand.rawValue, 0x80)

        // 别名一致性
        XCTAssertEqual(CompanionModifiers.control, .leftControl)
        XCTAssertEqual(CompanionModifiers.shift, .leftShift)
        XCTAssertEqual(CompanionModifiers.option, .leftOption)
        XCTAssertEqual(CompanionModifiers.command, .leftCommand)
        XCTAssertEqual(CompanionModifiers.alt, .leftOption)
        XCTAssertEqual(CompanionModifiers.win, .leftCommand)
        XCTAssertEqual(CompanionModifiers.rightAlt, .rightOption)
        XCTAssertEqual(CompanionModifiers.rightWin, .rightCommand)

        // 复合掩码与语义判断
        let combo: CompanionModifiers = [.leftCommand, .rightShift, .leftOption]
        XCTAssertTrue(combo.hasCommand)
        XCTAssertTrue(combo.hasShift)
        XCTAssertTrue(combo.hasOption)
        XCTAssertFalse(combo.hasControl)

        // 包含与字符串输出
        XCTAssertTrue(combo.description.contains("LCmd"))
        XCTAssertTrue(combo.description.contains("RShift"))
        XCTAssertTrue(combo.description.contains("LOpt"))
    }

    // 验证从键盘状态转换为伴侣修饰键掩码
    func testModifiersBridgeFromKeyboardState() {
        var modState = ModifierState()
        modState.press(.control)
        modState.press(.leftCommand)

        var inputState = InputState()
        inputState.shftdown(.left)

        let mods = CompanionModifiers(modifierState: modState, inputState: inputState)
        XCTAssertTrue(mods.contains(.leftControl))
        XCTAssertTrue(mods.contains(.leftCommand))
        XCTAssertTrue(mods.contains(.leftShift))
        XCTAssertFalse(mods.contains(.leftOption))
    }

    // 验证 16 位 USB HID Usage 标识与常量
    func testHIDUsageConstants() {
        XCTAssertEqual(CompanionHIDUsage.a.rawValue, 0x0004)
        XCTAssertEqual(CompanionHIDUsage.z.rawValue, 0x001D)
        XCTAssertEqual(CompanionHIDUsage.digit1.rawValue, 0x001E)
        XCTAssertEqual(CompanionHIDUsage.digit0.rawValue, 0x0027)
        XCTAssertEqual(CompanionHIDUsage.returnOrEnter.rawValue, 0x0028)
        XCTAssertEqual(CompanionHIDUsage.escape.rawValue, 0x0029)
        XCTAssertEqual(CompanionHIDUsage.deleteOrBackspace.rawValue, 0x002A)
        XCTAssertEqual(CompanionHIDUsage.tab.rawValue, 0x002B)
        XCTAssertEqual(CompanionHIDUsage.spacebar.rawValue, 0x002C)
        XCTAssertEqual(CompanionHIDUsage.f1.rawValue, 0x003A)
        XCTAssertEqual(CompanionHIDUsage.f12.rawValue, 0x0045)
        XCTAssertEqual(CompanionHIDUsage.rightArrow.rawValue, 0x004F)
        XCTAssertEqual(CompanionHIDUsage.leftArrow.rawValue, 0x0050)
        XCTAssertEqual(CompanionHIDUsage.downArrow.rawValue, 0x0051)
        XCTAssertEqual(CompanionHIDUsage.upArrow.rawValue, 0x0052)
        XCTAssertEqual(CompanionHIDUsage.leftControl.rawValue, 0x00E0)
        XCTAssertEqual(CompanionHIDUsage.leftCommand.rawValue, 0x00E3)

        // 字面量与格式化
        let usage: CompanionHIDUsage = 0x0029
        XCTAssertEqual(usage, .escape)
        XCTAssertEqual(usage.description, "0x0029")

        // UInt32 桥接截断
        let truncated = CompanionHIDUsage(UInt32(0x0001004A))
        XCTAssertEqual(truncated.rawValue, 0x004A)
    }

    // 验证五种动作类型的完整序列化与反序列化往返
    func testPacketRoundTrip() {
        let testCases: [CompanionPacket] = [
            CompanionPacket(
                action: .keyDown,
                modifiers: [.leftCommand],
                flags: 0,
                hidUsage: .a,
                param: 0,
                sequence: 1
            ),
            CompanionPacket(
                action: .keyUp,
                modifiers: [],
                flags: 0,
                hidUsage: .a,
                param: 0,
                sequence: 2
            ),
            CompanionPacket(
                action: .pulse,
                modifiers: [.leftControl, .leftOption],
                flags: 0x80,
                hidUsage: .tab,
                param: 35,
                sequence: 100
            ),
            CompanionPacket(
                action: .heartbeat,
                modifiers: [.leftShift],
                flags: 0,
                hidUsage: 0,
                param: 0,
                sequence: 101
            ),
            CompanionPacket(
                action: .resetAll,
                modifiers: [],
                flags: 0,
                hidUsage: 0,
                param: 0,
                sequence: 102
            ),
        ]

        for original in testCases {
            let encoded = original.encode()
            XCTAssertEqual(encoded.count, CompanionPacket.packetLength)

            guard let decoded = CompanionPacket.decode(from: encoded) else {
                XCTFail("Failed to decode packet for action: \(original.action)")
                continue
            }

            XCTAssertEqual(decoded.magic, CompanionPacket.magic)
            XCTAssertEqual(decoded.version, CompanionPacket.currentVersion)
            XCTAssertEqual(decoded.action, original.action)
            XCTAssertEqual(decoded.modifiers, original.modifiers)
            XCTAssertEqual(decoded.flags, original.flags)
            XCTAssertEqual(decoded.hidUsage, original.hidUsage)
            XCTAssertEqual(decoded.param, original.param)
            XCTAssertEqual(decoded.sequence, original.sequence)
            XCTAssertEqual(decoded, original)
        }
    }

    // 验证网络大端序字节排布
    func testPacketBigEndianByteOrder() {
        let packet = CompanionPacket(
            magic: CompanionPacket.magic,
            version: 1,
            action: .pulse,
            modifiers: [.leftControl, .leftOption], // 0x01 | 0x04 = 0x05
            flags: 0xAA,
            hidUsage: 0x1234,
            param: 0x0020, // 32 ms
            sequence: 0x01020304
        )

        let data = packet.encode()
        XCTAssertEqual(data.count, 16)

        // 0..3: magic "MBCP" (0x4D, 0x42, 0x43, 0x50)
        XCTAssertEqual(data[0], 0x4D)
        XCTAssertEqual(data[1], 0x42)
        XCTAssertEqual(data[2], 0x43)
        XCTAssertEqual(data[3], 0x50)

        // 4: version (1)
        XCTAssertEqual(data[4], 0x01)

        // 5: action (.pulse = 3)
        XCTAssertEqual(data[5], 0x03)

        // 6: modifiers (0x05)
        XCTAssertEqual(data[6], 0x05)

        // 7: flags (0xAA)
        XCTAssertEqual(data[7], 0xAA)

        // 8..9: hidUsage (0x12, 0x34) 大端序
        XCTAssertEqual(data[8], 0x12)
        XCTAssertEqual(data[9], 0x34)

        // 10..11: param (0x00, 0x20) 大端序
        XCTAssertEqual(data[10], 0x00)
        XCTAssertEqual(data[11], 0x20)

        // 12..15: sequence (0x01, 0x02, 0x03, 0x04) 大端序
        XCTAssertEqual(data[12], 0x01)
        XCTAssertEqual(data[13], 0x02)
        XCTAssertEqual(data[14], 0x03)
        XCTAssertEqual(data[15], 0x04)
    }

    // 验证非法报文拒绝保护
    func testInvalidPacketsRejected() {
        // 1. 长度不足 16 字节
        let shortData = Data(repeating: 0, count: 15)
        XCTAssertNil(CompanionPacket.decode(from: shortData))

        // 2. 空数据
        XCTAssertNil(CompanionPacket.decode(from: Data()))

        // 3. 错误魔数
        var badMagic = CompanionPacket.keyDown(usage: .escape, sequence: 1).encode()
        badMagic[0] = 0x00
        XCTAssertNil(CompanionPacket.decode(from: badMagic))

        // 4. 不支持的高版本号
        var badVersion = CompanionPacket.keyDown(usage: .escape, sequence: 1).encode()
        badVersion[4] = 2
        XCTAssertNil(CompanionPacket.decode(from: badVersion))

        // 5. 非法动作枚举
        var badAction = CompanionPacket.keyDown(usage: .escape, sequence: 1).encode()
        badAction[5] = 0x00
        XCTAssertNil(CompanionPacket.decode(from: badAction))
        badAction[5] = 0x99
        XCTAssertNil(CompanionPacket.decode(from: badAction))

        // 6. 超过 16 字节的有效数据包（应能成功提取前 16 字节）
        var longData = CompanionPacket.pulse(usage: .spacebar, sequence: 42).encode()
        longData.append(contentsOf: [0xFF, 0xEE, 0xDD])
        let parsedLong = CompanionPacket.decode(from: longData)
        XCTAssertNotNil(parsedLong)
        XCTAssertEqual(parsedLong?.action, .pulse)
        XCTAssertEqual(parsedLong?.hidUsage, .spacebar)
        XCTAssertEqual(parsedLong?.sequence, 42)
    }

    // 验证便捷工厂方法
    func testFactoryMethods() {
        let kd = CompanionPacket.keyDown(usage: .f5, modifiers: [.leftCommand], sequence: 10)
        XCTAssertEqual(kd.action, .keyDown)
        XCTAssertEqual(kd.hidUsage, .f5)
        XCTAssertEqual(kd.modifiers, [.leftCommand])
        XCTAssertEqual(kd.sequence, 10)

        let ku = CompanionPacket.keyUp(usage: .f5, modifiers: [.leftCommand], sequence: 11)
        XCTAssertEqual(ku.action, .keyUp)
        XCTAssertEqual(ku.hidUsage, .f5)
        XCTAssertEqual(ku.sequence, 11)

        let pulse = CompanionPacket.pulse(usage: .escape, durationMs: 25, sequence: 12)
        XCTAssertEqual(pulse.action, .pulse)
        XCTAssertEqual(pulse.hidUsage, .escape)
        XCTAssertEqual(pulse.param, 25)
        XCTAssertEqual(pulse.sequence, 12)

        let hb = CompanionPacket.heartbeat(modifiers: [.leftControl], sequence: 13)
        XCTAssertEqual(hb.action, .heartbeat)
        XCTAssertEqual(hb.modifiers, [.leftControl])
        XCTAssertEqual(hb.sequence, 13)

        let reset = CompanionPacket.resetAll(sequence: 14)
        XCTAssertEqual(reset.action, .resetAll)
        XCTAssertEqual(reset.sequence, 14)
    }

    // 查询当前进程驻留物理内存（字节）
    private func getResidentMemoryBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard kerr == KERN_SUCCESS else { return 0 }
        return UInt64(info.resident_size)
    }

    // 验证零堆分配内存写入与缓冲区解码
    func testZeroAllocationBufferWriteAndDecode() {
        let packet = CompanionPacket.pulse(
            usage: .escape,
            modifiers: [.leftCommand, .leftOption],
            durationMs: 25,
            sequence: 999
        )

        var stackBytes: (UInt64, UInt64) = (0, 0)
        let writeSuccess = withUnsafeMutableBytes(of: &stackBytes) { buffer in
            packet.write(to: buffer)
        }
        XCTAssertTrue(writeSuccess)

        let decoded = withUnsafeBytes(of: &stackBytes) { buffer in
            CompanionPacket.decode(from: buffer)
        }

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded, packet)

        // 验证栈上视图直接访问
        packet.withUnsafeBytes { buffer in
            XCTAssertEqual(buffer.count, 16)
            let directDecoded = CompanionPacket.decode(from: buffer)
            XCTAssertEqual(directDecoded, packet)
        }
    }

    // 验证高频报文编解码无内存泄漏与低堆内存消耗
    func testHighFrequencyMemoryStability() {
        let initialMem = getResidentMemoryBytes()

        for i in 0..<100_000 {
            let p = CompanionPacket.pulse(usage: .spacebar, sequence: UInt32(i))
            p.withUnsafeBytes { buffer in
                if let decoded = CompanionPacket.decode(from: buffer) {
                    _ = decoded.action
                }
            }
        }

        let finalMem = getResidentMemoryBytes()
        let delta = finalMem > initialMem ? finalMem - initialMem : 0
        // 100,000 次操作堆增量应严格在 1MB 之内，无内存悬垂
        XCTAssertLessThanOrEqual(delta, 1024 * 1024, "Memory delta \(delta) bytes exceeded 1MB limit")
    }

    // 验证 iOS 模拟器环境向 Mac 宿主机伴侣服务发送真实 UDP 报文链路
    func testSimulatorToHostUDPSend() throws {
        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        XCTAssertGreaterThanOrEqual(sock, 0)
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(52188).bigEndian
        inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr)

        let testPackets = [
            CompanionPacket.pulse(usage: .escape, durationMs: 25, sequence: 701),
            CompanionPacket.keyDown(usage: .a, modifiers: [.leftCommand], sequence: 702),
            CompanionPacket.keyUp(usage: .a, sequence: 703),
            CompanionPacket.pulse(usage: .f5, durationMs: 20, sequence: 704),
        ]

        for packet in testPackets {
            var raw: (UInt64, UInt64) = (0, 0)
            let sent = withUnsafeMutableBytes(of: &raw) { buffer -> Int in
                _ = packet.write(to: buffer)
                return withUnsafePointer(to: &addr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                        sendto(sock, buffer.baseAddress, CompanionPacket.packetLength, 0, saPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
            }
            XCTAssertEqual(sent, CompanionPacket.packetLength)
        }
    }

    // 验证 iOS 模拟器环境向远程 Windows 被控端伴侣服务 (10.1.1.2:52088) 发送真实 UDP 报文链路
    func testSimulatorToWindowsCompanionUDPSend() throws {
        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        XCTAssertGreaterThanOrEqual(sock, 0)
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(52088).bigEndian

        let targetHost = ProcessInfo.processInfo.environment["COMPANION_WIN_HOST"] ?? "10.1.1.2"
        inet_pton(AF_INET, targetHost, &addr.sin_addr)

        let testPackets = [
            // 1. Win 键脉冲 (HID 0x00E3, 50ms)
            CompanionPacket.pulse(usage: .leftGUI, durationMs: 50, sequence: 801),
            // 2. Alt + Tab 组合键 (HID 0x002B, Mods 0x04)
            CompanionPacket.keyDown(usage: .tab, modifiers: [.leftOption], sequence: 802),
            CompanionPacket.keyUp(usage: .tab, modifiers: [], sequence: 803),
            // 3. Escape 脉冲 (HID 0x0029, 25ms)
            CompanionPacket.pulse(usage: .escape, durationMs: 25, sequence: 804),
            // 4. F5 刷新脉冲 (HID 0x003E, 20ms)
            CompanionPacket.pulse(usage: .f5, durationMs: 20, sequence: 805),
            // 5. Ctrl 修饰键心跳同步
            CompanionPacket.heartbeat(modifiers: [.leftControl], sequence: 806),
            // 6. ResetAll 紧急复位
            CompanionPacket.resetAll(sequence: 807),
        ]

        for packet in testPackets {
            var raw: (UInt64, UInt64) = (0, 0)
            let sent = withUnsafeMutableBytes(of: &raw) { buffer -> Int in
                _ = packet.write(to: buffer)
                return withUnsafePointer(to: &addr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                        sendto(sock, buffer.baseAddress, CompanionPacket.packetLength, 0, saPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
            }
            XCTAssertEqual(sent, CompanionPacket.packetLength)
            usleep(25_000) // 25ms 间隔
        }
    }
}
