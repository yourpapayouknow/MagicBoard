// 伴侣网络通信桥接
import Foundation
import Network
import os

// 伴侣网络通信桥接管理
public final class CompanionBridge: @unchecked Sendable {
    public static let shared = CompanionBridge()

    private let queue = DispatchQueue(label: "com.magicboard.companion.bridge", qos: .userInteractive)
    private var connection: NWConnection?
    private let lock = OSAllocatedUnfairLock(initialState: State())

    // 内部状态
    private struct State {
        var config: CompanionConfig = CompanionConfig()
        var sequence: UInt32 = 0
    }

    public var isEnabled: Bool {
        lock.withLock { $0.config.enabled }
    }

    public var workMode: CompanionWorkMode {
        lock.withLock { $0.config.workMode }
    }

    public var targetOS: CompanionTargetOS {
        lock.withLock { $0.config.targetOS }
    }

    public var plsdur: UInt16 {
        lock.withLock { $0.config.pulseDurationMs }
    }

    public var curhost: String {
        lock.withLock { $0.config.host }
    }

    public var curport: UInt16 {
        lock.withLock { $0.config.port }
    }

    // 初始化桥接
    public init() {}

    deinit {
        stpconn()
    }

    // 更新配置
    public func cfg(with newConfig: CompanionConfig) {
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
                    self.stpconn()
                }
                if newConfig.enabled {
                    self.strtconn(host: newConfig.host, port: newConfig.port)
                }
            }
        }
    }

    // 发送脉冲按键
    public func sndpls(
        usage: CompanionHIDUsage,
        dur: UInt16? = nil,
        mods: CompanionModifiers? = nil
    ) {
        guard isEnabled else { return }
        let duration = dur ?? plsdur
        let modifiers = mods ?? []
        let seq = nxtseq()
        let packet = CompanionPacket.sndpls(usage: usage, modifiers: modifiers, durationMs: duration, sequence: seq)
        queue.async { [weak self] in
            self?.sndpkt(packet)
        }
    }

    // 发送按键按下
    public func snddn(
        usage: CompanionHIDUsage,
        mods: CompanionModifiers? = nil
    ) {
        guard isEnabled else { return }
        let modifiers = mods ?? []
        let seq = nxtseq()
        let packet = CompanionPacket.snddn(usage: usage, modifiers: modifiers, sequence: seq)
        queue.async { [weak self] in
            self?.sndpkt(packet)
        }
    }

    // 发送按键抬起
    public func sndup(
        usage: CompanionHIDUsage,
        mods: CompanionModifiers? = nil
    ) {
        guard isEnabled else { return }
        let modifiers = mods ?? []
        let seq = nxtseq()
        let packet = CompanionPacket.sndup(usage: usage, modifiers: modifiers, sequence: seq)
        queue.async { [weak self] in
            self?.sndpkt(packet)
        }
    }

    // 同步心跳
    public func synchrt(mods: CompanionModifiers) {
        guard isEnabled else { return }
        let seq = nxtseq()
        let packet = CompanionPacket.synchrt(modifiers: mods, sequence: seq)
        queue.async { [weak self] in
            self?.sndpkt(packet)
        }
    }

    // 重置全部按键
    public func rstall() {
        guard isEnabled else { return }
        let seq = nxtseq()
        let packet = CompanionPacket.rstall(sequence: seq)
        queue.async { [weak self] in
            self?.sndpkt(packet)
        }
    }

    // 排空发送队列
    public func flush() {
        queue.sync {}
    }

    // 生成递增序号
    private func nxtseq() -> UInt32 {
        lock.withLock { state in
            state.sequence &+= 1
            return state.sequence
        }
    }

    // 启动网络连接
    private func strtconn(host: String, port: UInt16) {
        let endpointHost = NWEndpoint.Host(host)
        let endpointPort = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port(rawValue: 52088)!
        let params = NWParameters.udp
        params.serviceClass = .responsiveData

        let conn = NWConnection(host: endpointHost, port: endpointPort, using: params)
        conn.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                break
            case .failed(let error):
                _ = error
            default:
                break
            }
        }
        conn.start(queue: queue)
        self.connection = conn
    }

    // 停止网络连接
    private func stpconn() {
        if let conn = connection {
            conn.cancel()
            connection = nil
        }
    }

    // 发送底层报文
    private func sndpkt(_ packet: CompanionPacket) {
        guard let conn = connection else { return }
        var stackBuffer: (UInt64, UInt64) = (0, 0)
        let wrote = withUnsafeMutableBytes(of: &stackBuffer) { buffer in
            packet.wrbuf(to: buffer)
        }
        guard wrote else { return }

        let data = withUnsafeBytes(of: &stackBuffer) { buffer in
            Data(buffer)
        }
        conn.send(content: data, completion: .idempotent)
    }
}
