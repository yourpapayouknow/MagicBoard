// 基于 Network.framework 的异步非阻塞伴侣通信客户端
import Foundation
import Network
import os

// 管理 iPad 键盘扩展端到远程电脑伴侣服务的 UDP 事件分流与桥接
public final class CompanionBridge: @unchecked Sendable {
    public static let shared = CompanionBridge()

    // 专用高优先级后台发包队列（非阻塞，保证主线程触摸与 UI 渲染平滑）
    private let queue = DispatchQueue(label: "com.magicboard.companion.bridge", qos: .userInteractive)

    // 底层 Network.framework UDP 连接
    private var connection: NWConnection?

    // 锁保护的可变状态（iOS 16+ 原生无锁化/极低开销锁）
    private let lock = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var config: CompanionConfig = CompanionConfig()
        var sequence: UInt32 = 0
    }

    // 快速只读属性
    public var isEnabled: Bool {
        lock.withLock { $0.config.enabled }
    }

    public var workMode: CompanionWorkMode {
        lock.withLock { $0.config.workMode }
    }

    public var targetOS: CompanionTargetOS {
        lock.withLock { $0.config.targetOS }
    }

    public var pulseDurationMs: UInt16 {
        lock.withLock { $0.config.pulseDurationMs }
    }

    public var currentHost: String {
        lock.withLock { $0.config.host }
    }

    public var currentPort: UInt16 {
        lock.withLock { $0.config.port }
    }

    public init() {}

    deinit {
        stopConnection()
    }

    // 更新伴侣配置并热重载底层 UDP 连接
    public func configure(with newConfig: CompanionConfig) {
        let (shouldReconnect, wasEnabled) = lock.withLock { state -> (Bool, Bool) in
            let old = state.config
            let reconnect = (old.host != newConfig.host) || (old.port != newConfig.port) || (old.enabled != newConfig.enabled)
            let enabled = old.enabled
            state.config = newConfig
            return (reconnect, enabled)
        }

        if shouldReconnect {
            queue.async { [weak self] in
                guard let self else { return }
                if wasEnabled {
                    self.stopConnection()
                }
                if newConfig.enabled {
                    self.startConnection(host: newConfig.host, port: newConfig.port)
                }
            }
        }
    }

    // 发送单包脉冲按键（KeyDown + 延时 + KeyUp 一次性完成，UDP 网络最安全稳健）
    public func sendPulse(
        usage: CompanionHIDUsage,
        durationMs: UInt16? = nil,
        modifiers: CompanionModifiers? = nil
    ) {
        guard isEnabled else { return }
        let dur = durationMs ?? pulseDurationMs
        let mods = modifiers ?? []
        let seq = nextSequence()
        let packet = CompanionPacket.pulse(usage: usage, modifiers: mods, durationMs: dur, sequence: seq)
        queue.async { [weak self] in
            self?.sendPacket(packet)
        }
    }

    // 发送按键按下
    public func sendKeyDown(
        usage: CompanionHIDUsage,
        modifiers: CompanionModifiers? = nil
    ) {
        guard isEnabled else { return }
        let mods = modifiers ?? []
        let seq = nextSequence()
        let packet = CompanionPacket.keyDown(usage: usage, modifiers: mods, sequence: seq)
        queue.async { [weak self] in
            self?.sendPacket(packet)
        }
    }

    // 发送按键抬起
    public func sendKeyUp(
        usage: CompanionHIDUsage,
        modifiers: CompanionModifiers? = nil
    ) {
        guard isEnabled else { return }
        let mods = modifiers ?? []
        let seq = nextSequence()
        let packet = CompanionPacket.keyUp(usage: usage, modifiers: mods, sequence: seq)
        queue.async { [weak self] in
            self?.sendPacket(packet)
        }
    }

    // 同步当前修饰键与探活心跳
    public func syncHeartbeat(modifiers: CompanionModifiers) {
        guard isEnabled else { return }
        let seq = nextSequence()
        let packet = CompanionPacket.heartbeat(modifiers: modifiers, sequence: seq)
        queue.async { [weak self] in
            self?.sendPacket(packet)
        }
    }

    // 紧急安全重置被控端全部按键与修饰键（键盘收起、取消或异常时调用）
    public func resetAll() {
        guard isEnabled else { return }
        let seq = nextSequence()
        let packet = CompanionPacket.resetAll(sequence: seq)
        queue.async { [weak self] in
            self?.sendPacket(packet)
        }
    }

    // 等待后台发包队列排空（主要用于测试与生命周期平滑同步）
    public func flush() {
        queue.sync {}
    }

    // 内部序号自增
    private func nextSequence() -> UInt32 {
        lock.withLock { state in
            state.sequence &+= 1
            return state.sequence
        }
    }

    // 启动 NWConnection
    private func startConnection(host: String, port: UInt16) {
        let endpointHost = NWEndpoint.Host(host)
        let endpointPort = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port(rawValue: 52088)!
        let params = NWParameters.udp
        // 限制流量为尽力而为、实时低延迟模式
        params.serviceClass = .responsiveData

        let conn = NWConnection(host: endpointHost, port: endpointPort, using: params)
        conn.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                break
            case .failed(let error):
                // UDP 连接失败记录
                _ = error
            default:
                break
            }
        }
        conn.start(queue: queue)
        self.connection = conn
    }

    // 停止连接
    private func stopConnection() {
        if let conn = connection {
            conn.cancel()
            connection = nil
        }
    }

    // 发送底层 16 字节定长报文（零堆内存泄漏、小对象内联优化）
    private func sendPacket(_ packet: CompanionPacket) {
        guard let conn = connection else { return }
        var stackBuffer: (UInt64, UInt64) = (0, 0)
        let wrote = withUnsafeMutableBytes(of: &stackBuffer) { buffer in
            packet.write(to: buffer)
        }
        guard wrote else { return }

        // 16 字节内存直接以小型内联 Data 传递，零动态堆内存开销
        let data = withUnsafeBytes(of: &stackBuffer) { buffer in
            Data(buffer)
        }
        conn.send(content: data, completion: .idempotent)
    }
}
