// 定义 MagicBoard 伴侣二进制通信协议（MBCP）
import Foundation

// 定义伴侣动作类型
public enum CompanionAction: UInt8, CaseIterable, Codable, Sendable, CustomStringConvertible {
    case keyDown = 0x01
    case keyUp = 0x02
    case pulse = 0x03
    case heartbeat = 0x04
    case resetAll = 0x05

    public var description: String {
        switch self {
        case .keyDown: "keyDown"
        case .keyUp: "keyUp"
        case .pulse: "pulse"
        case .heartbeat: "heartbeat"
        case .resetAll: "resetAll"
        }
    }
}

// 规范 8 位修饰键掩码位图
public struct CompanionModifiers: OptionSet, Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let leftControl = CompanionModifiers(rawValue: 1 << 0)
    public static let leftShift = CompanionModifiers(rawValue: 1 << 1)
    public static let leftOption = CompanionModifiers(rawValue: 1 << 2)
    public static let leftCommand = CompanionModifiers(rawValue: 1 << 3)
    public static let rightControl = CompanionModifiers(rawValue: 1 << 4)
    public static let rightShift = CompanionModifiers(rawValue: 1 << 5)
    public static let rightOption = CompanionModifiers(rawValue: 1 << 6)
    public static let rightCommand = CompanionModifiers(rawValue: 1 << 7)

    // 常用修饰键快捷别名
    public static let control: CompanionModifiers = .leftControl
    public static let shift: CompanionModifiers = .leftShift
    public static let option: CompanionModifiers = .leftOption
    public static let command: CompanionModifiers = .leftCommand
    public static let alt: CompanionModifiers = .leftOption
    public static let win: CompanionModifiers = .leftCommand
    public static let rightAlt: CompanionModifiers = .rightOption
    public static let rightWin: CompanionModifiers = .rightCommand

    // 便捷语义判断
    public var hasControl: Bool { contains(.leftControl) || contains(.rightControl) }
    public var hasShift: Bool { contains(.leftShift) || contains(.rightShift) }
    public var hasOption: Bool { contains(.leftOption) || contains(.rightOption) }
    public var hasCommand: Bool { contains(.leftCommand) || contains(.rightCommand) }

    // 从键盘修饰键与输入状态直接创建掩码
    public init(modifierState: ModifierState? = nil, inputState: InputState? = nil) {
        var mods: CompanionModifiers = []
        if let modifierState {
            if modifierState.contains(.control) { mods.insert(.leftControl) }
            if modifierState.contains(.leftOption) { mods.insert(.leftOption) }
            if modifierState.contains(.rightOption) { mods.insert(.rightOption) }
            if modifierState.contains(.leftCommand) { mods.insert(.leftCommand) }
            if modifierState.contains(.rightCommand) { mods.insert(.rightCommand) }
        }
        if let inputState {
            if inputState.shifted || inputState.shiftHeld {
                mods.insert(.leftShift)
            }
        }
        self = mods
    }

    public var description: String {
        var names: [String] = []
        if contains(.leftControl) { names.append("LCtrl") }
        if contains(.leftShift) { names.append("LShift") }
        if contains(.leftOption) { names.append("LOpt") }
        if contains(.leftCommand) { names.append("LCmd") }
        if contains(.rightControl) { names.append("RCtrl") }
        if contains(.rightShift) { names.append("RShift") }
        if contains(.rightOption) { names.append("ROpt") }
        if contains(.rightCommand) { names.append("RCmd") }
        return names.isEmpty ? "none" : names.joined(separator: "|")
    }
}

// 采用国际标准 USB HID Usage 16 位编码作为统一按键标识 (Page 0x07)
public struct CompanionHIDUsage: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public init(integerLiteral value: UInt16) {
        self.rawValue = value
    }

    public init(_ value: UInt16) {
        self.rawValue = value
    }

    public init(_ value: UInt32) {
        self.rawValue = UInt16(value & 0xFFFF)
    }

    public var description: String {
        String(format: "0x%04X", rawValue)
    }

    // 常用字母键 (0x04 ~ 0x1D)
    public static let a: CompanionHIDUsage = 0x0004
    public static let b: CompanionHIDUsage = 0x0005
    public static let c: CompanionHIDUsage = 0x0006
    public static let d: CompanionHIDUsage = 0x0007
    public static let e: CompanionHIDUsage = 0x0008
    public static let f: CompanionHIDUsage = 0x0009
    public static let g: CompanionHIDUsage = 0x000A
    public static let h: CompanionHIDUsage = 0x000B
    public static let i: CompanionHIDUsage = 0x000C
    public static let j: CompanionHIDUsage = 0x000D
    public static let k: CompanionHIDUsage = 0x000E
    public static let l: CompanionHIDUsage = 0x000F
    public static let m: CompanionHIDUsage = 0x0010
    public static let n: CompanionHIDUsage = 0x0011
    public static let o: CompanionHIDUsage = 0x0012
    public static let p: CompanionHIDUsage = 0x0013
    public static let q: CompanionHIDUsage = 0x0014
    public static let r: CompanionHIDUsage = 0x0015
    public static let s: CompanionHIDUsage = 0x0016
    public static let t: CompanionHIDUsage = 0x0017
    public static let u: CompanionHIDUsage = 0x0018
    public static let v: CompanionHIDUsage = 0x0019
    public static let w: CompanionHIDUsage = 0x001A
    public static let x: CompanionHIDUsage = 0x001B
    public static let y: CompanionHIDUsage = 0x001C
    public static let z: CompanionHIDUsage = 0x001D

    // 数字键 1~0 (0x1E ~ 0x27)
    public static let digit1: CompanionHIDUsage = 0x001E
    public static let digit2: CompanionHIDUsage = 0x001F
    public static let digit3: CompanionHIDUsage = 0x0020
    public static let digit4: CompanionHIDUsage = 0x0021
    public static let digit5: CompanionHIDUsage = 0x0022
    public static let digit6: CompanionHIDUsage = 0x0023
    public static let digit7: CompanionHIDUsage = 0x0024
    public static let digit8: CompanionHIDUsage = 0x0025
    public static let digit9: CompanionHIDUsage = 0x0026
    public static let digit0: CompanionHIDUsage = 0x0027

    // 常用控制与编辑键
    public static let returnOrEnter: CompanionHIDUsage = 0x0028
    public static let enter: CompanionHIDUsage = .returnOrEnter
    public static let escape: CompanionHIDUsage = 0x0029
    public static let deleteOrBackspace: CompanionHIDUsage = 0x002A
    public static let delete: CompanionHIDUsage = .deleteOrBackspace
    public static let tab: CompanionHIDUsage = 0x002B
    public static let spacebar: CompanionHIDUsage = 0x002C
    public static let hyphen: CompanionHIDUsage = 0x002D
    public static let minus: CompanionHIDUsage = .hyphen
    public static let equalSign: CompanionHIDUsage = 0x002E
    public static let equal: CompanionHIDUsage = .equalSign
    public static let openBracket: CompanionHIDUsage = 0x002F
    public static let leftBracket: CompanionHIDUsage = .openBracket
    public static let closeBracket: CompanionHIDUsage = 0x0030
    public static let rightBracket: CompanionHIDUsage = .closeBracket
    public static let backslash: CompanionHIDUsage = 0x0031
    public static let semicolon: CompanionHIDUsage = 0x0033
    public static let quote: CompanionHIDUsage = 0x0034
    public static let graveAccent: CompanionHIDUsage = 0x0035
    public static let grave: CompanionHIDUsage = .graveAccent
    public static let comma: CompanionHIDUsage = 0x0036
    public static let period: CompanionHIDUsage = 0x0037
    public static let slash: CompanionHIDUsage = 0x0038
    public static let capsLock: CompanionHIDUsage = 0x0039

    // 功能键 F1 ~ F12 (0x3A ~ 0x45)
    public static let f1: CompanionHIDUsage = 0x003A
    public static let f2: CompanionHIDUsage = 0x003B
    public static let f3: CompanionHIDUsage = 0x003C
    public static let f4: CompanionHIDUsage = 0x003D
    public static let f5: CompanionHIDUsage = 0x003E
    public static let f6: CompanionHIDUsage = 0x003F
    public static let f7: CompanionHIDUsage = 0x0040
    public static let f8: CompanionHIDUsage = 0x0041
    public static let f9: CompanionHIDUsage = 0x0042
    public static let f10: CompanionHIDUsage = 0x0043
    public static let f11: CompanionHIDUsage = 0x0044
    public static let f12: CompanionHIDUsage = 0x0045

    // 导航键与箭头
    public static let printScreen: CompanionHIDUsage = 0x0046
    public static let scrollLock: CompanionHIDUsage = 0x0047
    public static let pause: CompanionHIDUsage = 0x0048
    public static let insert: CompanionHIDUsage = 0x0049
    public static let home: CompanionHIDUsage = 0x004A
    public static let pageUp: CompanionHIDUsage = 0x004B
    public static let deleteForward: CompanionHIDUsage = 0x004C
    public static let end: CompanionHIDUsage = 0x004D
    public static let pageDown: CompanionHIDUsage = 0x004E
    public static let rightArrow: CompanionHIDUsage = 0x004F
    public static let leftArrow: CompanionHIDUsage = 0x0050
    public static let downArrow: CompanionHIDUsage = 0x0051
    public static let upArrow: CompanionHIDUsage = 0x0052

    // 修饰键 HID 编码 (0xE0 ~ 0xE7)
    public static let leftControl: CompanionHIDUsage = 0x00E0
    public static let leftShift: CompanionHIDUsage = 0x00E1
    public static let leftOption: CompanionHIDUsage = 0x00E2
    public static let leftCommand: CompanionHIDUsage = 0x00E3
    public static let leftGUI: CompanionHIDUsage = .leftCommand
    public static let leftWin: CompanionHIDUsage = .leftCommand
    public static let rightControl: CompanionHIDUsage = 0x00E4
    public static let rightShift: CompanionHIDUsage = 0x00E5
    public static let rightOption: CompanionHIDUsage = 0x00E6
    public static let rightCommand: CompanionHIDUsage = 0x00E7
    public static let rightGUI: CompanionHIDUsage = .rightCommand
    public static let rightWin: CompanionHIDUsage = .rightCommand
}

// 伴侣定长二进制通信报文（16 字节固定长度）
public struct CompanionPacket: Equatable, Sendable {
    // 协议魔数 ASCII "MBCP" (MagicBoard Companion Protocol)
    public static let magic: UInt32 = 0x4D424350
    // 当前协议版本
    public static let currentVersion: UInt8 = 1
    // 固定报文总长度（16 字节）
    public static let packetLength: Int = 16

    public var magic: UInt32
    public var version: UInt8
    public var action: CompanionAction
    public var modifiers: CompanionModifiers
    public var flags: UInt8
    public var hidUsage: CompanionHIDUsage
    public var param: UInt16
    public var sequence: UInt32

    // 创建伴侣报文
    public init(
        magic: UInt32 = CompanionPacket.magic,
        version: UInt8 = CompanionPacket.currentVersion,
        action: CompanionAction,
        modifiers: CompanionModifiers = [],
        flags: UInt8 = 0,
        hidUsage: CompanionHIDUsage = 0,
        param: UInt16 = 0,
        sequence: UInt32 = 0
    ) {
        self.magic = magic
        self.version = version
        self.action = action
        self.modifiers = modifiers
        self.flags = flags
        self.hidUsage = hidUsage
        self.param = param
        self.sequence = sequence
    }

    // 将 16 字节报文以网络大端序直接写入目标内存缓冲区（支持零堆分配）
    @discardableResult
    public func write(to buffer: UnsafeMutableRawBufferPointer) -> Bool {
        guard buffer.count >= Self.packetLength, let base = buffer.baseAddress else { return false }

        // 0..3: magic (UInt32, Big-Endian)
        let beMagic = magic.bigEndian
        memcpy(base, [beMagic], 4)

        // 4: version (UInt8)
        base.storeBytes(of: version, toByteOffset: 4, as: UInt8.self)

        // 5: action (UInt8)
        base.storeBytes(of: action.rawValue, toByteOffset: 5, as: UInt8.self)

        // 6: modifiers (UInt8)
        base.storeBytes(of: modifiers.rawValue, toByteOffset: 6, as: UInt8.self)

        // 7: flags (UInt8)
        base.storeBytes(of: flags, toByteOffset: 7, as: UInt8.self)

        // 8..9: hidUsage (UInt16, Big-Endian)
        let beUsage = hidUsage.rawValue.bigEndian
        memcpy(base.advanced(by: 8), [beUsage], 2)

        // 10..11: param (UInt16, Big-Endian)
        let beParam = param.bigEndian
        memcpy(base.advanced(by: 10), [beParam], 2)

        // 12..15: sequence (UInt32, Big-Endian)
        let beSeq = sequence.bigEndian
        memcpy(base.advanced(by: 12), [beSeq], 4)

        return true
    }

    // 在栈上提供零堆分配（Zero-Allocation）的直接只读内存视图回调
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        var raw: (UInt64, UInt64) = (0, 0) // 16 字节纯栈上分配
        return try withUnsafeMutableBytes(of: &raw) { (buffer: UnsafeMutableRawBufferPointer) in
            write(to: buffer)
            return try body(UnsafeRawBufferPointer(buffer))
        }
    }

    // 编码为 16 字节网络大端序二进制数据
    public func encode() -> Data {
        var data = Data(count: Self.packetLength)
        data.withUnsafeMutableBytes { buffer in
            _ = write(to: buffer)
        }
        return data
    }

    // 从原始内存缓冲区反序列化报文（严格校验长度、魔数、版本和合法动作，零堆分配）
    public static func decode(from buffer: UnsafeRawBufferPointer) -> CompanionPacket? {
        guard buffer.count >= packetLength, let base = buffer.baseAddress else { return nil }

        // 0..3: magic
        var rawMagic: UInt32 = 0
        memcpy(&rawMagic, base, 4)
        let parsedMagic = UInt32(bigEndian: rawMagic)
        guard parsedMagic == magic else { return nil }

        // 4: version
        let parsedVersion = base.load(fromByteOffset: 4, as: UInt8.self)
        guard parsedVersion == currentVersion else { return nil }

        // 5: action
        let actionRaw = base.load(fromByteOffset: 5, as: UInt8.self)
        guard let parsedAction = CompanionAction(rawValue: actionRaw) else { return nil }

        // 6: modifiers
        let modRaw = base.load(fromByteOffset: 6, as: UInt8.self)
        let parsedModifiers = CompanionModifiers(rawValue: modRaw)

        // 7: flags
        let parsedFlags = base.load(fromByteOffset: 7, as: UInt8.self)

        // 8..9: hidUsage
        var rawUsage: UInt16 = 0
        memcpy(&rawUsage, base.advanced(by: 8), 2)
        let parsedUsage = CompanionHIDUsage(rawValue: UInt16(bigEndian: rawUsage))

        // 10..11: param
        var rawParam: UInt16 = 0
        memcpy(&rawParam, base.advanced(by: 10), 2)
        let parsedParam = UInt16(bigEndian: rawParam)

        // 12..15: sequence
        var rawSeq: UInt32 = 0
        memcpy(&rawSeq, base.advanced(by: 12), 4)
        let parsedSeq = UInt32(bigEndian: rawSeq)

        return CompanionPacket(
            magic: parsedMagic,
            version: parsedVersion,
            action: parsedAction,
            modifiers: parsedModifiers,
            flags: parsedFlags,
            hidUsage: parsedUsage,
            param: parsedParam,
            sequence: parsedSeq
        )
    }

    // 从 Data 反序列化报文
    public static func decode(from data: Data) -> CompanionPacket? {
        data.withUnsafeBytes { decode(from: $0) }
    }

    // 便捷工厂方法：按键按下
    public static func keyDown(
        usage: CompanionHIDUsage,
        modifiers: CompanionModifiers = [],
        sequence: UInt32 = 0
    ) -> CompanionPacket {
        CompanionPacket(
            action: .keyDown,
            modifiers: modifiers,
            hidUsage: usage,
            sequence: sequence
        )
    }

    // 便捷工厂方法：按键抬起
    public static func keyUp(
        usage: CompanionHIDUsage,
        modifiers: CompanionModifiers = [],
        sequence: UInt32 = 0
    ) -> CompanionPacket {
        CompanionPacket(
            action: .keyUp,
            modifiers: modifiers,
            hidUsage: usage,
            sequence: sequence
        )
    }

    // 便捷工厂方法：单包脉冲（自动按下并在服务端延时 durationMs 后抬起）
    public static func pulse(
        usage: CompanionHIDUsage,
        modifiers: CompanionModifiers = [],
        durationMs: UInt16 = 20,
        sequence: UInt32 = 0
    ) -> CompanionPacket {
        CompanionPacket(
            action: .pulse,
            modifiers: modifiers,
            hidUsage: usage,
            param: durationMs,
            sequence: sequence
        )
    }

    // 便捷工厂方法：状态同步与心跳
    public static func heartbeat(
        modifiers: CompanionModifiers = [],
        sequence: UInt32 = 0
    ) -> CompanionPacket {
        CompanionPacket(
            action: .heartbeat,
            modifiers: modifiers,
            sequence: sequence
        )
    }

    // 便捷工厂方法：紧急重置所有按键
    public static func resetAll(sequence: UInt32 = 0) -> CompanionPacket {
        CompanionPacket(
            action: .resetAll,
            sequence: sequence
        )
    }
}
