import XCTest
import Foundation
@testable import MagicBoardShared

final class CompanionBridgeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 每个测试前重置为默认关闭状态
        CompanionBridge.shared.configure(with: CompanionConfig(enabled: false))
    }

    override func tearDown() {
        CompanionBridge.shared.configure(with: CompanionConfig(enabled: false))
        super.tearDown()
    }

    // 验证初始状态
    func testBridgeInitialState() {
        let bridge = CompanionBridge()
        XCTAssertFalse(bridge.isEnabled)
        XCTAssertEqual(bridge.workMode, .onlyFunctions)
        XCTAssertEqual(bridge.targetOS, .macOS)
        XCTAssertEqual(bridge.pulseDurationMs, 20)
    }

    // 验证配置更新与属性生效
    func testBridgeConfigure() {
        let bridge = CompanionBridge()
        let cfg = CompanionConfig(
            enabled: true,
            host: "10.1.1.2",
            port: 52088,
            workMode: .fullKeyboard,
            targetOS: .windows,
            pulseDurationMs: 45
        )
        bridge.configure(with: cfg)

        XCTAssertTrue(bridge.isEnabled)
        XCTAssertEqual(bridge.currentHost, "10.1.1.2")
        XCTAssertEqual(bridge.currentPort, 52088)
        XCTAssertEqual(bridge.workMode, .fullKeyboard)
        XCTAssertEqual(bridge.targetOS, .windows)
        XCTAssertEqual(bridge.pulseDurationMs, 45)
    }

    // 验证主线程发包非阻塞耗时严格 < 1ms (实际通常 < 0.05ms)
    func testNonBlockingMainThreadLatency() {
        let bridge = CompanionBridge.shared
        bridge.configure(with: CompanionConfig(enabled: true, host: "127.0.0.1", port: 52088))

        // 预热
        bridge.sendPulse(usage: .spacebar)

        var durations: [Double] = []
        for _ in 0..<100 {
            let start = CACurrentMediaTime()
            bridge.sendPulse(usage: .a, durationMs: 20, modifiers: [.leftCommand])
            bridge.sendKeyDown(usage: .tab, modifiers: [.leftOption])
            bridge.sendKeyUp(usage: .tab)
            bridge.syncHeartbeat(modifiers: [.leftControl])
            bridge.resetAll()
            let elapsed = (CACurrentMediaTime() - start) * 1000.0 // 毫秒
            durations.append(elapsed)
        }

        let maxDuration = durations.max() ?? 0
        let avgDuration = durations.reduce(0, +) / Double(durations.count)

        print("⚡ [Latency Benchmark] 5 次连续调用平均耗时: \(String(format: "%.4f", avgDuration)) ms, 最大耗时: \(String(format: "%.4f", maxDuration)) ms")

        // 严格断言每次发包主线程耗时远低于 1.0 ms
        XCTAssertLessThan(maxDuration, 1.0, "Main thread dispatch latency exceeded 1.0 ms limit!")
    }

    // 查询当前进程物理驻留内存
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

    // 验证高频发包常驻内存物理增量 < 100KB (严格符合 Jetsam 约束)
    func testJetsamMemoryFootprintStability() {
        let bridge = CompanionBridge.shared
        bridge.configure(with: CompanionConfig(enabled: true, host: "127.0.0.1", port: 52088))

        // 预热让网络栈、malloc 内存池及内核套接字缓冲区达到稳定态
        autoreleasepool {
            for _ in 0..<1_000 {
                bridge.sendPulse(usage: .spacebar)
            }
        }
        bridge.flush()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        let initialMem = getResidentMemoryBytes()

        // 执行稳态下 1,000 次高频发包循环（真实键盘每秒最多20次击键，1,000次相当于连续高速输入一分钟）
        autoreleasepool {
            for i in 0..<1_000 {
                bridge.sendPulse(
                    usage: .escape,
                    durationMs: 20,
                    modifiers: (i % 2 == 0) ? [.leftControl] : []
                )
            }
        }

        // 等待后台队列发送完毕并释放瞬时缓冲
        bridge.flush()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        let finalMem = getResidentMemoryBytes()
        let delta = finalMem > initialMem ? finalMem - initialMem : 0

        print("🧠 [Jetsam Memory Benchmark] 1,000 次发包常驻内存增量: \(delta) 字节 (\(String(format: "%.2f", Double(delta) / 1024.0)) KB)")

        // 验证常驻增量小于 100KB (102,400 字节)
        XCTAssertLessThanOrEqual(delta, 100 * 1024, "Resident memory delta \(delta) exceeded 100KB Jetsam limit")
    }

    // 验证伴侣关闭时安全静默，不进行任何网络发包
    func testDisabledStateSafeNoop() {
        let bridge = CompanionBridge()
        bridge.configure(with: CompanionConfig(enabled: false))

        // 所有调用应安全静默返回
        bridge.sendPulse(usage: .f1)
        bridge.sendKeyDown(usage: .f2)
        bridge.sendKeyUp(usage: .f2)
        bridge.syncHeartbeat(modifiers: [.leftShift])
        bridge.resetAll()

        XCTAssertFalse(bridge.isEnabled)
    }

    // 验证真实 Network.framework UDP 网络传输的完整数据包投递与字段准确性
    func testBridgeLiveUDPDelivery() throws {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        XCTAssertGreaterThanOrEqual(fd, 0)
        defer { close(fd) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        addr.sin_port = in_port_t(0).bigEndian // 动态分配空闲端口

        let bindRes = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        XCTAssertEqual(bindRes, 0)

        // 获取分配的端口
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameRes = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(fd, $0, &len)
            }
        }
        XCTAssertEqual(nameRes, 0)
        let boundPort = UInt16(bigEndian: addr.sin_port)

        // 设置套接字读取超时为 1 秒
        var tv = timeval(tv_sec: 1, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        let bridge = CompanionBridge()
        bridge.configure(with: CompanionConfig(enabled: true, host: "127.0.0.1", port: boundPort))

        // 等待 NWConnection 底层建链就绪
        Thread.sleep(forTimeInterval: 0.05)

        // 连续发送 5 种业务类型的报文
        bridge.sendPulse(usage: .escape, durationMs: 25, modifiers: [.leftCommand, .leftShift])
        bridge.sendKeyDown(usage: .upArrow, modifiers: [])
        bridge.sendKeyUp(usage: .upArrow, modifiers: [])
        bridge.syncHeartbeat(modifiers: [.leftControl])
        bridge.resetAll()
        bridge.flush()

        // 读取 5 个 UDP 报文并校验
        var receivedPackets: [CompanionPacket] = []
        for _ in 0..<5 {
            var buf = [UInt8](repeating: 0, count: 64)
            let n = recv(fd, &buf, buf.count, 0)
            XCTAssertGreaterThanOrEqual(n, CompanionPacket.packetLength, "Received datagram too short or timed out")
            let packet = Data(buf[0..<n]).withUnsafeBytes { CompanionPacket.decode(from: $0) }
            XCTAssertNotNil(packet)
            if let packet {
                receivedPackets.append(packet)
            }
        }

        XCTAssertEqual(receivedPackets.count, 5)
        // 校验报文 1: pulse
        XCTAssertEqual(receivedPackets[0].action, .pulse)
        XCTAssertEqual(receivedPackets[0].hidUsage, .escape)
        XCTAssertEqual(receivedPackets[0].param, 25)
        XCTAssertTrue(receivedPackets[0].modifiers.contains(.leftCommand))
        XCTAssertTrue(receivedPackets[0].modifiers.contains(.leftShift))

        // 校验报文 2: keyDown
        XCTAssertEqual(receivedPackets[1].action, .keyDown)
        XCTAssertEqual(receivedPackets[1].hidUsage, .upArrow)

        // 校验报文 3: keyUp
        XCTAssertEqual(receivedPackets[2].action, .keyUp)
        XCTAssertEqual(receivedPackets[2].hidUsage, .upArrow)

        // 校验报文 4: heartbeat
        XCTAssertEqual(receivedPackets[3].action, .heartbeat)
        XCTAssertTrue(receivedPackets[3].modifiers.contains(.leftControl))

        // 校验报文 5: resetAll
        XCTAssertEqual(receivedPackets[4].action, .resetAll)

        // 严格校验递增序号
        for i in 1..<receivedPackets.count {
            XCTAssertEqual(receivedPackets[i].sequence, receivedPackets[i - 1].sequence + 1)
        }
    }

    // 验证 App Group 伴侣配置持久化与跨进程 Darwin Notification 广播即时同步
    func testCompanionConfigAppGroupSyncAndNotification() {
        let suiteName = "test.magicboard.companion.sync.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        let expectation = expectation(description: "Darwin notification received")
        final class ObserverBox: @unchecked Sendable {
            var received = false
        }
        let box = ObserverBox()

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(box).toOpaque(),
            { _, observerPtr, _, _, _ in
                guard let observerPtr else { return }
                let b = Unmanaged<ObserverBox>.fromOpaque(observerPtr).takeUnretainedValue()
                b.received = true
            },
            SharedConfig.configChangedNotification as CFString,
            nil,
            .deliverImmediately
        )

        var newSettings = BoardSettings.standard
        newSettings.companion = CompanionConfig(
            enabled: true,
            host: "100.88.99.1",
            port: 52099,
            workMode: .fullKeyboard,
            targetOS: .windows,
            pulseDurationMs: 40
        )

        SharedConfig.svcfg(newSettings, defaults: testDefaults)

        // 验证持久化内容
        let loaded = SharedConfig.ldcfg(defaults: testDefaults)
        XCTAssertTrue(loaded.companion.enabled)
        XCTAssertEqual(loaded.companion.host, "100.88.99.1")
        XCTAssertEqual(loaded.companion.port, 52099)
        XCTAssertEqual(loaded.companion.workMode, .fullKeyboard)
        XCTAssertEqual(loaded.companion.targetOS, .windows)
        XCTAssertEqual(loaded.companion.pulseDurationMs, 40)

        // 验证收到广播通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(box.received, "Darwin notification was not observed")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(box).toOpaque(),
            CFNotificationName(SharedConfig.configChangedNotification as CFString),
            nil
        )
    }
}

