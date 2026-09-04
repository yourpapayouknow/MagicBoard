// 伴侣通信协议测试
@testable import MagicBoardShared
import Foundation
import XCTest

// 伴侣协议测试用例
final class CompanionProtocolTests: XCTestCase {
    // 测试常量
    func testconst() {
        XCTAssertEqual(CompanionPacket.magic, 0x4D424350)
        XCTAssertEqual(CompanionPacket.currentVersion, 1)
        XCTAssertEqual(CompanionPacket.packetLength, 16)
    }

    // 测试动作枚举
    func testact() {
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

    // 测试修饰键掩码
    func testmod() {
        XCTAssertEqual(CompanionModifiers.leftControl.rawValue, 0x01)
        XCTAssertEqual(CompanionModifiers.leftShift.rawValue, 0x02)
        XCTAssertEqual(CompanionModifiers.leftOption.rawValue, 0x04)
        XCTAssertEqual(CompanionModifiers.leftCommand.rawValue, 0x08)
        XCTAssertEqual(CompanionModifiers.rightControl.rawValue, 0x10)
        XCTAssertEqual(CompanionModifiers.rightShift.rawValue, 0x20)
        XCTAssertEqual(CompanionModifiers.rightOption.rawValue, 0x40)
        XCTAssertEqual(CompanionModifiers.rightCommand.rawValue, 0x80)

        XCTAssertEqual(CompanionModifiers.control, .leftControl)
        XCTAssertEqual(CompanionModifiers.shift, .leftShift)
        XCTAssertEqual(CompanionModifiers.option, .leftOption)
        XCTAssertEqual(CompanionModifiers.command, .leftCommand)
        XCTAssertEqual(CompanionModifiers.alt, .leftOption)
        XCTAssertEqual(CompanionModifiers.win, .leftCommand)
        XCTAssertEqual(CompanionModifiers.rightAlt, .rightOption)
        XCTAssertEqual(CompanionModifiers.rightWin, .rightCommand)

        let combo: CompanionModifiers = [.leftCommand, .rightShift, .leftOption]
        XCTAssertTrue(combo.hasCommand)
        XCTAssertTrue(combo.hasShift)
        XCTAssertTrue(combo.hasOption)
        XCTAssertFalse(combo.hasControl)

        XCTAssertTrue(combo.description.contains("LCmd"))
        XCTAssertTrue(combo.description.contains("RShift"))
        XCTAssertTrue(combo.description.contains("LOpt"))
    }

    // 测试键盘状态转换
    func testmodkbd() {
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

    // 测试HID键码
    func testhid() {
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

        let usage: CompanionHIDUsage = 0x0029
        XCTAssertEqual(usage, .escape)
        XCTAssertEqual(usage.description, "0x0029")

        let truncated = CompanionHIDUsage(UInt32(0x0001004A))
        XCTAssertEqual(truncated.rawValue, 0x004A)
    }

    // 测试报文往返编解码
    func testround() {
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
            let encoded = original.enc()
            XCTAssertEqual(encoded.count, CompanionPacket.packetLength)

            guard let decoded = CompanionPacket.dec(from: encoded) else {
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

    // 测试大端序排布
    func testbe() {
        let packet = CompanionPacket(
            magic: CompanionPacket.magic,
            version: 1,
            action: .pulse,
            modifiers: [.leftControl, .leftOption],
            flags: 0xAA,
            hidUsage: 0x1234,
            param: 0x0020,
            sequence: 0x01020304
        )

        let data = packet.enc()
        XCTAssertEqual(data.count, 16)

        XCTAssertEqual(data[0], 0x4D)
        XCTAssertEqual(data[1], 0x42)
        XCTAssertEqual(data[2], 0x43)
        XCTAssertEqual(data[3], 0x50)

        XCTAssertEqual(data[4], 0x01)
        XCTAssertEqual(data[5], 0x03)
        XCTAssertEqual(data[6], 0x05)
        XCTAssertEqual(data[7], 0xAA)

        XCTAssertEqual(data[8], 0x12)
        XCTAssertEqual(data[9], 0x34)

        XCTAssertEqual(data[10], 0x00)
        XCTAssertEqual(data[11], 0x20)

        XCTAssertEqual(data[12], 0x01)
        XCTAssertEqual(data[13], 0x02)
        XCTAssertEqual(data[14], 0x03)
        XCTAssertEqual(data[15], 0x04)
    }

    // 测试非法报文校验
    func testinv() {
        let shortData = Data(repeating: 0, count: 15)
        XCTAssertNil(CompanionPacket.dec(from: shortData))

        XCTAssertNil(CompanionPacket.dec(from: Data()))

        var badMagic = CompanionPacket.snddn(usage: .escape, sequence: 1).enc()
        badMagic[0] = 0x00
        XCTAssertNil(CompanionPacket.dec(from: badMagic))

        var badVersion = CompanionPacket.snddn(usage: .escape, sequence: 1).enc()
        badVersion[4] = 2
        XCTAssertNil(CompanionPacket.dec(from: badVersion))

        var badAction = CompanionPacket.snddn(usage: .escape, sequence: 1).enc()
        badAction[5] = 0x00
        XCTAssertNil(CompanionPacket.dec(from: badAction))
        badAction[5] = 0x99
        XCTAssertNil(CompanionPacket.dec(from: badAction))

        var longData = CompanionPacket.sndpls(usage: .spacebar, sequence: 42).enc()
        longData.append(contentsOf: [0xFF, 0xEE, 0xDD])
        let parsedLong = CompanionPacket.dec(from: longData)
        XCTAssertNotNil(parsedLong)
        XCTAssertEqual(parsedLong?.action, .pulse)
        XCTAssertEqual(parsedLong?.hidUsage, .spacebar)
        XCTAssertEqual(parsedLong?.sequence, 42)
    }

    // 测试工厂构造方法
    func testfct() {
        let kd = CompanionPacket.snddn(usage: .f5, modifiers: [.leftCommand], sequence: 10)
        XCTAssertEqual(kd.action, .keyDown)
        XCTAssertEqual(kd.hidUsage, .f5)
        XCTAssertEqual(kd.modifiers, [.leftCommand])
        XCTAssertEqual(kd.sequence, 10)

        let ku = CompanionPacket.sndup(usage: .f5, modifiers: [.leftCommand], sequence: 11)
        XCTAssertEqual(ku.action, .keyUp)
        XCTAssertEqual(ku.hidUsage, .f5)
        XCTAssertEqual(ku.sequence, 11)

        let pulse = CompanionPacket.sndpls(usage: .escape, durationMs: 25, sequence: 12)
        XCTAssertEqual(pulse.action, .pulse)
        XCTAssertEqual(pulse.hidUsage, .escape)
        XCTAssertEqual(pulse.param, 25)
        XCTAssertEqual(pulse.sequence, 12)

        let hb = CompanionPacket.synchrt(modifiers: [.leftControl], sequence: 13)
        XCTAssertEqual(hb.action, .heartbeat)
        XCTAssertEqual(hb.modifiers, [.leftControl])
        XCTAssertEqual(hb.sequence, 13)

        let reset = CompanionPacket.rstall(sequence: 14)
        XCTAssertEqual(reset.action, .resetAll)
        XCTAssertEqual(reset.sequence, 14)
    }

    // 获取物理常驻内存
    private func getresmem() -> UInt64 {
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

    // 测试直接内存写入
    func testzero() {
        let packet = CompanionPacket.sndpls(
            usage: .escape,
            modifiers: [.leftCommand, .leftOption],
            durationMs: 25,
            sequence: 999
        )

        var stackBytes: (UInt64, UInt64) = (0, 0)
        let writeSuccess = withUnsafeMutableBytes(of: &stackBytes) { buffer in
            packet.wrbuf(to: buffer)
        }
        XCTAssertTrue(writeSuccess)

        let decoded = withUnsafeBytes(of: &stackBytes) { buffer in
            CompanionPacket.dec(from: buffer)
        }

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded, packet)

        packet.withbytes { buffer in
            XCTAssertEqual(buffer.count, 16)
            let directDecoded = CompanionPacket.dec(from: buffer)
            XCTAssertEqual(directDecoded, packet)
        }
    }

    // 测试高频编解码内存
    func testhifrq() {
        let initialMem = getresmem()

        for i in 0..<100_000 {
            let p = CompanionPacket.sndpls(usage: .spacebar, sequence: UInt32(i))
            p.withbytes { buffer in
                if let decoded = CompanionPacket.dec(from: buffer) {
                    _ = decoded.action
                }
            }
        }

        let finalMem = getresmem()
        let delta = finalMem > initialMem ? finalMem - initialMem : 0
        XCTAssertLessThanOrEqual(delta, 1024 * 1024, "Memory delta \(delta) bytes exceeded 1MB limit")
    }

    // 测试向本地服务发包
    func testsimmac() throws {
        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        XCTAssertGreaterThanOrEqual(sock, 0)
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(52188).bigEndian
        inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr)

        let testPackets = [
            CompanionPacket.sndpls(usage: .escape, durationMs: 25, sequence: 701),
            CompanionPacket.snddn(usage: .a, modifiers: [.leftCommand], sequence: 702),
            CompanionPacket.sndup(usage: .a, sequence: 703),
            CompanionPacket.sndpls(usage: .f5, durationMs: 20, sequence: 704),
        ]

        for packet in testPackets {
            var raw: (UInt64, UInt64) = (0, 0)
            let sent = withUnsafeMutableBytes(of: &raw) { buffer -> Int in
                _ = packet.wrbuf(to: buffer)
                return withUnsafePointer(to: &addr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                        sendto(sock, buffer.baseAddress, CompanionPacket.packetLength, 0, saPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
            }
            XCTAssertEqual(sent, CompanionPacket.packetLength)
        }
    }

    // 测试向远程Windows服务发包
    func testsimwin() throws {
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
            CompanionPacket.sndpls(usage: .leftGUI, durationMs: 50, sequence: 801),
            CompanionPacket.snddn(usage: .tab, modifiers: [.leftOption], sequence: 802),
            CompanionPacket.sndup(usage: .tab, modifiers: [], sequence: 803),
            CompanionPacket.sndpls(usage: .escape, durationMs: 25, sequence: 804),
            CompanionPacket.sndpls(usage: .f5, durationMs: 20, sequence: 805),
            CompanionPacket.synchrt(modifiers: [.leftControl], sequence: 806),
            CompanionPacket.rstall(sequence: 807),
        ]

        for packet in testPackets {
            var raw: (UInt64, UInt64) = (0, 0)
            let sent = withUnsafeMutableBytes(of: &raw) { buffer -> Int in
                _ = packet.wrbuf(to: buffer)
                return withUnsafePointer(to: &addr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                        sendto(sock, buffer.baseAddress, CompanionPacket.packetLength, 0, saPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
            }
            XCTAssertEqual(sent, CompanionPacket.packetLength)
            usleep(25_000)
        }
    }
}
