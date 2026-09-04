// MagicBoard macOS 原生伴侣服务（单文件命令行原生服务）
// 监听来自 iPad 键盘端的 MBCP 二进制 UDP 报文并注入 macOS 系统事件队列
import Foundation
import CoreGraphics
import ApplicationServices
import Darwin

// 伴侣通信协议常量与数据结构
struct MBCP {
    static let magic: UInt32 = 0x4D424350 // ASCII "MBCP"
    static let version: UInt8 = 1
    static let packetLength: Int = 16

    enum Action: UInt8 {
        case keyDown = 0x01
        case keyUp = 0x02
        case pulse = 0x03
        case heartbeat = 0x04
        case resetAll = 0x05
    }

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

    struct Packet {
        let action: Action
        let modifiers: Modifiers
        let flags: UInt8
        let hidUsage: UInt16
        let param: UInt16
        let sequence: UInt32

        static func decode(from buffer: UnsafeRawBufferPointer) -> Packet? {
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

// 标准 USB HID Usage (Page 0x07) 到 macOS CGKeyCode 转换器
enum KeyCodeMapper {
    // 映射表：USB HID Usage -> CGKeyCode (kVK_*)
    static let usageToCGKey: [UInt16: CGKeyCode] = [
        // 字母 A-Z (0x04 ~ 0x1D)
        0x0004: 0x00, // A
        0x0005: 0x0B, // B
        0x0006: 0x08, // C
        0x0007: 0x02, // D
        0x0008: 0x0E, // E
        0x0009: 0x03, // F
        0x000A: 0x05, // G
        0x000B: 0x04, // H
        0x000C: 0x22, // I
        0x000D: 0x26, // J
        0x000E: 0x28, // K
        0x000F: 0x25, // L
        0x0010: 0x2E, // M
        0x0011: 0x2D, // N
        0x0012: 0x1F, // O
        0x0013: 0x23, // P
        0x0014: 0x0C, // Q
        0x0015: 0x0F, // R
        0x0016: 0x01, // S
        0x0017: 0x11, // T
        0x0018: 0x20, // U
        0x0019: 0x09, // V
        0x001A: 0x0D, // W
        0x001B: 0x07, // X
        0x001C: 0x10, // Y
        0x001D: 0x06, // Z

        // 主键盘数字 1-0 (0x1E ~ 0x27)
        0x001E: 0x12, // 1
        0x001F: 0x13, // 2
        0x0020: 0x14, // 3
        0x0021: 0x15, // 4
        0x0022: 0x17, // 5
        0x0023: 0x16, // 6
        0x0024: 0x1A, // 7
        0x0025: 0x1C, // 8
        0x0026: 0x19, // 9
        0x0027: 0x1D, // 0

        // 常用控制与标点键
        0x0028: 0x24, // Return / Enter
        0x0029: 0x35, // Escape
        0x002A: 0x33, // Delete (Backspace)
        0x002B: 0x30, // Tab
        0x002C: 0x31, // Spacebar
        0x002D: 0x1B, // Hyphen / Minus (-)
        0x002E: 0x18, // Equal (=)
        0x002F: 0x21, // Open Bracket ([)
        0x0030: 0x1E, // Close Bracket (])
        0x0031: 0x2A, // Backslash (\)
        0x0033: 0x29, // Semicolon (;)
        0x0034: 0x27, // Quote (')
        0x0035: 0x32, // Grave Accent (`)
        0x0036: 0x2B, // Comma (,)
        0x0037: 0x2F, // Period (.)
        0x0038: 0x2C, // Slash (/)
        0x0039: 0x39, // Caps Lock

        // 功能键 F1 - F12 (0x3A ~ 0x45)
        0x003A: 0x7A, // F1
        0x003B: 0x78, // F2
        0x003C: 0x63, // F3
        0x003D: 0x76, // F4
        0x003E: 0x60, // F5
        0x003F: 0x61, // F6
        0x0040: 0x62, // F7
        0x0041: 0x64, // F8
        0x0042: 0x65, // F9
        0x0043: 0x6D, // F10
        0x0044: 0x67, // F11
        0x0045: 0x6F, // F12

        // 导航与方向键 (0x46 ~ 0x52)
        0x0046: 0x69, // PrintScreen (F13)
        0x0047: 0x6B, // ScrollLock (F14)
        0x0048: 0x71, // Pause (F15)
        0x0049: 0x72, // Insert (Help)
        0x004A: 0x73, // Home
        0x004B: 0x74, // PageUp
        0x004C: 0x75, // Delete Forward
        0x004D: 0x77, // End
        0x004E: 0x79, // PageDown
        0x004F: 0x7C, // Right Arrow
        0x0050: 0x7B, // Left Arrow
        0x0051: 0x7D, // Down Arrow
        0x0052: 0x7E, // Up Arrow

        // 修饰键 (0xE0 ~ 0xE7)
        0x00E0: 0x3B, // Left Control
        0x00E1: 0x38, // Left Shift
        0x00E2: 0x3A, // Left Option (Alt)
        0x00E3: 0x37, // Left Command (GUI)
        0x00E4: 0x3E, // Right Control
        0x00E5: 0x3C, // Right Shift
        0x00E6: 0x3D, // Right Option
        0x00E7: 0x36, // Right Command
    ]

    static func toCGKeyCode(_ usage: UInt16) -> CGKeyCode? {
        usageToCGKey[usage]
    }
}

// 管理 macOS CoreGraphics 系统键盘事件注入
final class KeyboardInjector {
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private let lock = NSLock()

    // 跟踪活动按键与按下时刻
    private(set) var activeKeys: Set<CGKeyCode> = []
    private(set) var activeModifiers: MBCP.Modifiers = []
    private(set) var lastPacketTime: Date = Date()

    // 辅助功能权限检测
    static func checkAccessibility(prompt: Bool) -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [checkOptPrompt: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    // 注入普通按键按下或抬起
    func injectKey(code: CGKeyCode, isDown: Bool, modifiers: MBCP.Modifiers) {
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
            print("[\(timestamp())] ⚠️ 创建 CGEvent 失败 (code: \(code))")
            return
        }
        event.flags = modifiers.cgEventFlags
        event.post(tap: .cghidEventTap)
    }

    // 执行单包脉冲（Pulse）：按下并在指定延时后自动抬起
    func injectPulse(code: CGKeyCode, durationMs: UInt16, modifiers: MBCP.Modifiers) {
        let dur = max(5, min(durationMs, 500))
        injectKey(code: code, isDown: true, modifiers: modifiers)

        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(Int(dur))) { [weak self] in
            self?.injectKey(code: code, isDown: false, modifiers: modifiers)
        }
    }

    // 同步心跳状态与修饰键
    func syncHeartbeat(modifiers: MBCP.Modifiers) {
        lock.lock()
        defer { lock.unlock() }
        lastPacketTime = Date()
        activeModifiers = modifiers
    }

    // 紧急重置：安全释放所有按下的普通按键与修饰键
    func resetAll(reason: String = "手动重置") {
        lock.lock()
        let keysToRelease = activeKeys
        activeKeys.removeAll()
        activeModifiers = []
        lastPacketTime = Date()
        lock.unlock()

        print("[\(timestamp())] 🛡️ 执行 resetAll (\(reason))，正在安全释放所有按键...")

        // 释放所有已跟踪的普通键
        for code in keysToRelease {
            if let event = CGEvent(keyboardEventSource: eventSource, virtualKey: code, keyDown: false) {
                event.flags = []
                event.post(tap: .cghidEventTap)
            }
        }

        // 显式释放全部 8 个修饰键以防悬挂
        let modifierKeys: [CGKeyCode] = [
            0x37, // Left Command
            0x36, // Right Command
            0x3A, // Left Option
            0x3D, // Right Option
            0x3B, // Left Control
            0x3E, // Right Control
            0x38, // Left Shift
            0x3C, // Right Shift
        ]
        for modKey in modifierKeys {
            if let event = CGEvent(keyboardEventSource: eventSource, virtualKey: modKey, keyDown: false) {
                event.flags = []
                event.post(tap: .cghidEventTap)
            }
        }

        print("[\(timestamp())] ✅ 所有按键与修饰键已全部复位释放。")
    }

    // 检查看门狗超时（若 >= 1.5 秒无包且有按键悬空则重置）
    func checkWatchdog() {
        lock.lock()
        let hasActive = !activeKeys.isEmpty || !activeModifiers.isEmpty
        let elapsed = Date().timeIntervalSince(lastPacketTime)
        lock.unlock()

        if hasActive && elapsed >= 1.5 {
            resetAll(reason: String(format: "看门狗超时 (已超时 %.2f 秒)", elapsed))
        }
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}

// 伴侣服务主程序
final class CompanionServer {
    private let port: UInt16
    private let injector = KeyboardInjector()
    private var isRunning = true
    private var socketFD: Int32 = -1

    init(port: UInt16 = 52088) {
        self.port = port
    }

    func start() {
        printBanner()

        // 1. 检测辅助功能权限
        if !KeyboardInjector.checkAccessibility(prompt: false) {
            print("⚠️ [警告] 当前进程缺少 macOS 辅助功能 (Accessibility) 权限！")
            print("   键盘事件注入将无法生效。正在呼出系统授权面板...")
            _ = KeyboardInjector.checkAccessibility(prompt: true)
            print("   👉 请在 [系统设置 -> 隐私与安全性 -> 辅助功能] 中允许当前终端或程序，然后重新启动。")
        } else {
            print("✅ 辅助功能权限验证通过 (Accessibility Trusted)。")
        }

        // 2. 创建 UDP Socket
        socketFD = socket(AF_INET, SOCK_DGRAM, 0)
        guard socketFD >= 0 else {
            fatalError("❌ 创建 UDP Socket 失败: \(String(cString: strerror(errno)))")
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
            fatalError("❌ 绑定 UDP 端口 \(port) 失败: \(String(cString: strerror(errno)))")
        }

        print("🚀 MagicBoard 伴侣服务已就绪，正在监听 UDP 端口 \(port)...")
        print("💡 提示：按 Ctrl+C 可停止服务，iPad 键盘端输入时将实时捕获并注入。")

        // 3. 启动看门狗定时线程 (每 200ms 检测一次)
        startWatchdogThread()

        // 4. 主循环接收并分发 UDP 报文
        runReceiveLoop()
    }

    private func startWatchdogThread() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            while let self = self, self.isRunning {
                Thread.sleep(forTimeInterval: 0.2)
                self.injector.checkWatchdog()
            }
        }
    }

    private func runReceiveLoop() {
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
                guard let packet = MBCP.Packet.decode(from: rawBuffer) else { return }
                handlePacket(packet)
            }
        }
    }

    private func handlePacket(_ packet: MBCP.Packet) {
        switch packet.action {
        case .keyDown:
            if let keyCode = KeyCodeMapper.toCGKeyCode(packet.hidUsage) {
                print("[\(timeStr())] ⬇️ KeyDown: HID 0x\(String(format: "%04X", packet.hidUsage)) -> CGKey 0x\(String(format: "%02X", keyCode)) (seq: \(packet.sequence), mods: \(packet.modifiers.rawValue))")
                injector.injectKey(code: keyCode, isDown: true, modifiers: packet.modifiers)
            } else {
                print("[\(timeStr())] ⚠️ 未知 HID Usage 0x\(String(format: "%04X", packet.hidUsage))")
            }

        case .keyUp:
            if let keyCode = KeyCodeMapper.toCGKeyCode(packet.hidUsage) {
                print("[\(timeStr())] ⬆️ KeyUp: HID 0x\(String(format: "%04X", packet.hidUsage)) -> CGKey 0x\(String(format: "%02X", keyCode)) (seq: \(packet.sequence))")
                injector.injectKey(code: keyCode, isDown: false, modifiers: packet.modifiers)
            }

        case .pulse:
            if let keyCode = KeyCodeMapper.toCGKeyCode(packet.hidUsage) {
                let dur = packet.param > 0 ? packet.param : 20
                print("[\(timeStr())] ⚡ Pulse: HID 0x\(String(format: "%04X", packet.hidUsage)) -> CGKey 0x\(String(format: "%02X", keyCode)) (\(dur)ms, seq: \(packet.sequence), mods: \(packet.modifiers.rawValue))")
                injector.injectPulse(code: keyCode, durationMs: dur, modifiers: packet.modifiers)
            }

        case .heartbeat:
            injector.syncHeartbeat(modifiers: packet.modifiers)

        case .resetAll:
            injector.resetAll(reason: "收到客户端 ResetAll 指令")
        }
    }

    private func printBanner() {
        print("""
        ============================================================
           ✨ MagicBoard Companion Server (macOS Native) ✨
           协议: MBCP v1 (16-byte UDP) | 端口: \(port)
           看门狗超时: 1.5 秒 | 注入引擎: CoreGraphics HID
        ============================================================
        """)
    }

    private func timeStr() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}

// 禁用行缓冲，确保管道与终端日志实时刷新
setlinebuf(stdout)

// 命令行参数解析并启动
var listenPort: UInt16 = 52088
var args = CommandLine.arguments.dropFirst()

while !args.isEmpty {
    let arg = args.removeFirst()
    if (arg == "--port" || arg == "-p"), !args.isEmpty {
        if let val = UInt16(args.removeFirst()) {
            listenPort = val
        }
    } else if arg == "--help" || arg == "-h" {
        print("""
        MagicBoard macOS Companion Server
        用法:
          magicboard-companion-mac [--port <PORT>]

        参数:
          -p, --port <PORT>   指定 UDP 监听端口 (默认: 52088)
          -h, --help          显示帮助信息
        """)
        exit(0)
    }
}

let server = CompanionServer(port: listenPort)
server.start()
