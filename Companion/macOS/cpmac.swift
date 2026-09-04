// 伴侣macOS原生服务
import Foundation
import CoreGraphics
import ApplicationServices
import Darwin

// 伴侣通信协议
struct MBCP {
    static let magic: UInt32 = 0x4D424350
    static let version: UInt8 = 1
    static let packetLength: Int = 16

    // 动作类型
    enum Action: UInt8 {
        case keyDown = 0x01
        case keyUp = 0x02
        case pulse = 0x03
        case heartbeat = 0x04
        case resetAll = 0x05
    }

    // 修饰键掩码
    struct Modifiers: OptionSet {
        let rawValue: UInt8

        static let leftControl = Modifiers(rawValue: 1 << 0)
        static let leftShift = Modifiers(rawValue: 1 << 1)
        static let leftOption = Modifiers(rawValue: 1 << 2)
        static let leftCommand = Modifiers(rawValue: 1 << 3)
        static let rightControl = Modifiers(rawValue: 1 << 4)
        static let rightShift = Modifiers(rawValue: 1 << 5)
        static let rightOption = Modifiers(rawValue: 1 << 6)
        static let rightCommand = Modifiers(rawValue: 1 << 7)

        var cgEventFlags: CGEventFlags {
            var flags: CGEventFlags = []
            if contains(.leftCommand) || contains(.rightCommand) { flags.insert(.maskCommand) }
            if contains(.leftOption) || contains(.rightOption) { flags.insert(.maskAlternate) }
            if contains(.leftControl) || contains(.rightControl) { flags.insert(.maskControl) }
            if contains(.leftShift) || contains(.rightShift) { flags.insert(.maskShift) }
            return flags
        }
    }

    // 通信报文
    struct Packet {
        let action: Action
        let modifiers: Modifiers
        let flags: UInt8
        let hidUsage: UInt16
        let param: UInt16
        let sequence: UInt32

        // 解码报文
        static func dec(from buffer: UnsafeRawBufferPointer) -> Packet? {
            guard buffer.count >= packetLength, let base = buffer.baseAddress else { return nil }

            var rawMagic: UInt32 = 0
            memcpy(&rawMagic, base, 4)
            guard UInt32(bigEndian: rawMagic) == magic else { return nil }

            let parsedVersion = base.load(fromByteOffset: 4, as: UInt8.self)
            guard parsedVersion == version else { return nil }

            let actionRaw = base.load(fromByteOffset: 5, as: UInt8.self)
            guard let action = Action(rawValue: actionRaw) else { return nil }

            let modRaw = base.load(fromByteOffset: 6, as: UInt8.self)
            let modifiers = Modifiers(rawValue: modRaw)
            let flags = base.load(fromByteOffset: 7, as: UInt8.self)

            var rawUsage: UInt16 = 0
            memcpy(&rawUsage, base.advanced(by: 8), 2)
            let hidUsage = UInt16(bigEndian: rawUsage)

            var rawParam: UInt16 = 0
            memcpy(&rawParam, base.advanced(by: 10), 2)
            let param = UInt16(bigEndian: rawParam)

            var rawSeq: UInt32 = 0
            memcpy(&rawSeq, base.advanced(by: 12), 4)
            let sequence = UInt32(bigEndian: rawSeq)

            return Packet(
                action: action,
                modifiers: modifiers,
                flags: flags,
                hidUsage: hidUsage,
                param: param,
                sequence: sequence
            )
        }
    }
}

// 键码映射表
enum KeyCodeMapper {
    static let usageToCGKey: [UInt16: CGKeyCode] = [
        0x0004: 0x00, 0x0005: 0x0B, 0x0006: 0x08, 0x0007: 0x02,
        0x0008: 0x0E, 0x0009: 0x03, 0x000A: 0x05, 0x000B: 0x04,
        0x000C: 0x22, 0x000D: 0x26, 0x000E: 0x28, 0x000F: 0x25,
        0x0010: 0x2E, 0x0011: 0x2D, 0x0012: 0x1F, 0x0013: 0x23,
        0x0014: 0x0C, 0x0015: 0x0F, 0x0016: 0x01, 0x0017: 0x11,
        0x0018: 0x20, 0x0019: 0x09, 0x001A: 0x0D, 0x001B: 0x07,
        0x001C: 0x10, 0x001D: 0x06,
        0x001E: 0x12, 0x001F: 0x13, 0x0020: 0x14, 0x0021: 0x15,
        0x0022: 0x17, 0x0023: 0x16, 0x0024: 0x1A, 0x0025: 0x1C,
        0x0026: 0x19, 0x0027: 0x1D,
        0x0028: 0x24, 0x0029: 0x35, 0x002A: 0x33, 0x002B: 0x30,
        0x002C: 0x31, 0x002D: 0x1B, 0x002E: 0x18, 0x002F: 0x21,
        0x0030: 0x1E, 0x0031: 0x2A, 0x0033: 0x29, 0x0034: 0x27,
        0x0035: 0x32, 0x0036: 0x2B, 0x0037: 0x2F, 0x0038: 0x2C,
        0x0039: 0x39,
        0x003A: 0x7A, 0x003B: 0x78, 0x003C: 0x63, 0x003D: 0x76,
        0x003E: 0x60, 0x003F: 0x61, 0x0040: 0x62, 0x0041: 0x64,
        0x0042: 0x65, 0x0043: 0x6D, 0x0044: 0x67, 0x0045: 0x6F,
        0x0046: 0x69, 0x0047: 0x6B, 0x0048: 0x71, 0x0049: 0x72,
        0x004A: 0x73, 0x004B: 0x74, 0x004C: 0x75, 0x004D: 0x77,
        0x004E: 0x79, 0x004F: 0x7C, 0x0050: 0x7B, 0x0051: 0x7D,
        0x0052: 0x7E,
        0x00E0: 0x3B, 0x00E1: 0x38, 0x00E2: 0x3A, 0x00E3: 0x37,
        0x00E4: 0x3E, 0x00E5: 0x3C, 0x00E6: 0x3D, 0x00E7: 0x36,
    ]

    // 转换键码
    static func tocgkey(_ usage: UInt16) -> CGKeyCode? {
        usageToCGKey[usage]
    }
}

// 键盘事件注入
final class KeyboardInjector {
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private let lock = NSLock()

    private(set) var activeKeys: Set<CGKeyCode> = []
    private(set) var activeModifiers: MBCP.Modifiers = []
    private(set) var lastPacketTime: Date = Date()

    // 检查权限
    static func chkax(prompt: Bool) -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [checkOptPrompt: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    // 注入按键
    func injkey(code: CGKeyCode, isDown: Bool, modifiers: MBCP.Modifiers) {
        lock.lock()
        defer { lock.unlock() }

        lastPacketTime = Date()
        if isDown {
            activeKeys.insert(code)
        } else {
            activeKeys.remove(code)
        }
        activeModifiers = modifiers

        guard let event = CGEvent(keyboardEventSource: eventSource, virtualKey: code, keyDown: isDown) else {
            return
        }
        event.flags = modifiers.cgEventFlags
        event.post(tap: .cghidEventTap)
    }

    // 注入脉冲
    func injpls(code: CGKeyCode, durationMs: UInt16, modifiers: MBCP.Modifiers) {
        let dur = max(5, min(durationMs, 500))
        injkey(code: code, isDown: true, modifiers: modifiers)

        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(Int(dur))) { [weak self] in
            self?.injkey(code: code, isDown: false, modifiers: modifiers)
        }
    }

    // 同步心跳
    func synchrt(modifiers: MBCP.Modifiers) {
        lock.lock()
        defer { lock.unlock() }
        lastPacketTime = Date()
        activeModifiers = modifiers
    }

    // 重置按键
    func rstall(reason: String = "手动重置") {
        lock.lock()
        let keysToRelease = activeKeys
        activeKeys.removeAll()
        activeModifiers = []
        lastPacketTime = Date()
        lock.unlock()

        print("[\(tms())] 执行 rstall (\(reason))")

        for code in keysToRelease {
            if let event = CGEvent(keyboardEventSource: eventSource, virtualKey: code, keyDown: false) {
                event.flags = []
                event.post(tap: .cghidEventTap)
            }
        }

        let modifierKeys: [CGKeyCode] = [
            0x37, 0x36, 0x3A, 0x3D, 0x3B, 0x3E, 0x38, 0x3C,
        ]
        for modKey in modifierKeys {
            if let event = CGEvent(keyboardEventSource: eventSource, virtualKey: modKey, keyDown: false) {
                event.flags = []
                event.post(tap: .cghidEventTap)
            }
        }
    }

    // 检查超时
    func chkwtdg() {
        lock.lock()
        let hasActive = !activeKeys.isEmpty || !activeModifiers.isEmpty
        let elapsed = Date().timeIntervalSince(lastPacketTime)
        lock.unlock()

        if hasActive && elapsed >= 1.5 {
            rstall(reason: "看门狗超时")
        }
    }

    // 格式化时间
    private func tms() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}

// 伴侣服务端
final class CompanionServer {
    private let port: UInt16
    private let injector = KeyboardInjector()
    private var isRunning = true
    private var socketFD: Int32 = -1

    init(port: UInt16 = 52088) {
        self.port = port
    }

    // 启动服务
    func strt() {
        prntbnr()

        if !KeyboardInjector.chkax(prompt: false) {
            print("⚠️ 缺少辅助功能权限，尝试请求授权...")
            _ = KeyboardInjector.chkax(prompt: true)
        } else {
            print("✅ 辅助功能权限验证通过")
        }

        socketFD = socket(AF_INET, SOCK_DGRAM, 0)
        guard socketFD >= 0 else {
            fatalError("创建 UDP Socket 失败")
        }

        var opt: Int32 = 1
        setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(socketFD, SOL_SOCKET, SO_REUSEPORT, &opt, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            fatalError("绑定 UDP 端口 \(port) 失败")
        }

        print("🚀 正在监听 UDP 端口 \(port)")

        strtwtdg()
        rcvloop()
    }

    // 启动看门狗
    private func strtwtdg() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            while let self = self, self.isRunning {
                Thread.sleep(forTimeInterval: 0.2)
                self.injector.chkwtdg()
            }
        }
    }

    // 循环接收
    private func rcvloop() {
        var buffer = [UInt8](repeating: 0, count: 256)

        while isRunning {
            var clientAddr = sockaddr_in()
            var clientLen = socklen_t(MemoryLayout<sockaddr_in>.size)

            let bytesRead = withUnsafeMutablePointer(to: &clientAddr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                    recvfrom(socketFD, &buffer, buffer.count, 0, saPtr, &clientLen)
                }
            }

            guard bytesRead >= MBCP.packetLength else { continue }

            buffer.withUnsafeBytes { rawBuffer in
                guard let packet = MBCP.Packet.dec(from: rawBuffer) else { return }
                hndlpkt(packet)
            }
        }
    }

    // 处理报文
    private func hndlpkt(_ packet: MBCP.Packet) {
        switch packet.action {
        case .keyDown:
            if let keyCode = KeyCodeMapper.tocgkey(packet.hidUsage) {
                print("[\(tmstr())] ⬇️ KeyDown: 0x\(String(format: "%04X", packet.hidUsage)) (seq: \(packet.sequence))")
                injector.injkey(code: keyCode, isDown: true, modifiers: packet.modifiers)
            }
        case .keyUp:
            if let keyCode = KeyCodeMapper.tocgkey(packet.hidUsage) {
                print("[\(tmstr())] ⬆️ KeyUp: 0x\(String(format: "%04X", packet.hidUsage)) (seq: \(packet.sequence))")
                injector.injkey(code: keyCode, isDown: false, modifiers: packet.modifiers)
            }
        case .pulse:
            if let keyCode = KeyCodeMapper.tocgkey(packet.hidUsage) {
                let dur = packet.param > 0 ? packet.param : 20
                print("[\(tmstr())] ⚡ Pulse: 0x\(String(format: "%04X", packet.hidUsage)) (\(dur)ms, seq: \(packet.sequence))")
                injector.injpls(code: keyCode, durationMs: dur, modifiers: packet.modifiers)
            }
        case .heartbeat:
            injector.synchrt(modifiers: packet.modifiers)
        case .resetAll:
            injector.rstall(reason: "收到 resetAll")
        }
    }

    // 打印横幅
    private func prntbnr() {
        print("MagicBoard macOS 伴侣服务已启动，端口: \(port)")
    }

    // 格式化时间
    private func tmstr() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}

setlinebuf(stdout)

var listenPort: UInt16 = 52088
var args = CommandLine.arguments.dropFirst()

while !args.isEmpty {
    let arg = args.removeFirst()
    if (arg == "--port" || arg == "-p"), !args.isEmpty {
        if let val = UInt16(args.removeFirst()) {
            listenPort = val
        }
    } else if arg == "--help" || arg == "-h" {
        print("用法: cpmac [--port <PORT>]")
        exit(0)
    }
}

let server = CompanionServer(port: listenPort)
server.strt()
