// 伴侣通信桥接单元测试
import XCTest
import Foundation
@testable import MagicBoardShared

// 伴侣桥接测试用例
final class CompanionBridgeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        CompanionBridge.shared.cfg(with: CompanionConfig(enabled: false))
    }

    override func tearDown() {
        CompanionBridge.shared.cfg(with: CompanionConfig(enabled: false))
        super.tearDown()
    }

    // 测试初始状态
    func testinit() {
        let bridge = CompanionBridge()
        XCTAssertFalse(bridge.isEnabled)
        XCTAssertEqual(bridge.workMode, .onlyFunctions)
        XCTAssertEqual(bridge.targetOS, .macOS)
        XCTAssertEqual(bridge.plsdur, 20)
    }

    // 测试配置更新
    func testcfg() {
        let bridge = CompanionBridge()
        let cfg = CompanionConfig(
            enabled: true,
            host: "10.1.1.2",
            port: 52088,
            workMode: .fullKeyboard,
            targetOS: .windows,
            pulseDurationMs: 45
        )
        bridge.cfg(with: cfg)

        XCTAssertTrue(bridge.isEnabled)
        XCTAssertEqual(bridge.curhost, "10.1.1.2")
        XCTAssertEqual(bridge.curport, 52088)
        XCTAssertEqual(bridge.workMode, .fullKeyboard)
        XCTAssertEqual(bridge.targetOS, .windows)
        XCTAssertEqual(bridge.plsdur, 45)
    }

    // 测试发包低延迟
    func testlat() {
        let bridge = CompanionBridge.shared
        bridge.cfg(with: CompanionConfig(enabled: true, host: "127.0.0.1", port: 52088))

        bridge.sndpls(usage: .spacebar)

        var durations: [Double] = []
        for _ in 0..<100 {
            let start = CACurrentMediaTime()
            bridge.sndpls(usage: .a, dur: 20, mods: [.leftCommand])
            bridge.snddn(usage: .tab, mods: [.leftOption])
            bridge.sndup(usage: .tab)
            bridge.synchrt(mods: [.leftControl])
            bridge.rstall()
            let elapsed = (CACurrentMediaTime() - start) * 1000.0
            durations.append(elapsed)
        }

        let maxDuration = durations.max() ?? 0
        let avgDuration = durations.reduce(0, +) / Double(durations.count)

        print("⚡ [Latency Benchmark] 5 次连续调用平均耗时: \(String(format: "%.4f", avgDuration)) ms, 最大耗时: \(String(format: "%.4f", maxDuration)) ms")

        XCTAssertLessThan(maxDuration, 1.0, "Main thread dispatch latency exceeded 1.0 ms limit!")
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

    // 测试内存开销稳定性
    func testmem() {
        let bridge = CompanionBridge.shared
        bridge.cfg(with: CompanionConfig(enabled: true, host: "127.0.0.1", port: 52088))

        autoreleasepool {
            for _ in 0..<1_000 {
                bridge.sndpls(usage: .spacebar)
            }
        }
        bridge.flush()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        let initialMem = getresmem()

        autoreleasepool {
            for i in 0..<1_000 {
                bridge.sndpls(
                    usage: .escape,
                    dur: 20,
                    mods: (i % 2 == 0) ? [.leftControl] : []
                )
            }
        }

        bridge.flush()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        let finalMem = getresmem()
        let delta = finalMem > initialMem ? finalMem - initialMem : 0

        print("🧠 [Jetsam Memory Benchmark] 1,000 次发包常驻内存增量: \(delta) 字节 (\(String(format: "%.2f", Double(delta) / 1024.0)) KB)")

        XCTAssertLessThanOrEqual(delta, 100 * 1024, "Resident memory delta \(delta) exceeded 100KB Jetsam limit")
    }

    // 测试未启用时静默
    func testnoop() {
        let bridge = CompanionBridge()
        bridge.cfg(with: CompanionConfig(enabled: false))

        bridge.sndpls(usage: .f1)
        bridge.snddn(usage: .f2)
        bridge.sndup(usage: .f2)
        bridge.synchrt(mods: [.leftShift])
        bridge.rstall()

        XCTAssertFalse(bridge.isEnabled)
    }

    // 测试实时数据包投递
    func testudp() throws {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        XCTAssertGreaterThanOrEqual(fd, 0)
        defer { close(fd) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        addr.sin_port = in_port_t(0).bigEndian

        let bindRes = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        XCTAssertEqual(bindRes, 0)

        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameRes = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(fd, $0, &len)
            }
        }
        XCTAssertEqual(nameRes, 0)
        let boundPort = UInt16(bigEndian: addr.sin_port)

        var tv = timeval(tv_sec: 1, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        let bridge = CompanionBridge()
        bridge.cfg(with: CompanionConfig(enabled: true, host: "127.0.0.1", port: boundPort))

        Thread.sleep(forTimeInterval: 0.05)

        bridge.sndpls(usage: .escape, dur: 25, mods: [.leftCommand, .leftShift])
        bridge.snddn(usage: .upArrow, mods: [])
        bridge.sndup(usage: .upArrow, mods: [])
        bridge.synchrt(mods: [.leftControl])
        bridge.rstall()
        bridge.flush()

        var receivedPackets: [CompanionPacket] = []
        for _ in 0..<5 {
            var buf = [UInt8](repeating: 0, count: 64)
            let n = recv(fd, &buf, buf.count, 0)
            XCTAssertGreaterThanOrEqual(n, CompanionPacket.packetLength, "Received datagram too short or timed out")
            let packet = Data(buf[0..<n]).withUnsafeBytes { CompanionPacket.dec(from: $0) }
            XCTAssertNotNil(packet)
            if let packet {
                receivedPackets.append(packet)
            }
        }

        XCTAssertEqual(receivedPackets.count, 5)

        XCTAssertEqual(receivedPackets[0].action, .pulse)
        XCTAssertEqual(receivedPackets[0].hidUsage, .escape)
        XCTAssertEqual(receivedPackets[0].param, 25)
        XCTAssertTrue(receivedPackets[0].modifiers.contains(.leftCommand))
        XCTAssertTrue(receivedPackets[0].modifiers.contains(.leftShift))

        XCTAssertEqual(receivedPackets[1].action, .keyDown)
        XCTAssertEqual(receivedPackets[1].hidUsage, .upArrow)

        XCTAssertEqual(receivedPackets[2].action, .keyUp)
        XCTAssertEqual(receivedPackets[2].hidUsage, .upArrow)

        XCTAssertEqual(receivedPackets[3].action, .heartbeat)
        XCTAssertTrue(receivedPackets[3].modifiers.contains(.leftControl))

        XCTAssertEqual(receivedPackets[4].action, .resetAll)

        for i in 1..<receivedPackets.count {
            XCTAssertEqual(receivedPackets[i].sequence, receivedPackets[i - 1].sequence + 1)
        }
    }

    // 测试配置同步与通知
    func testsync() {
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

        let loaded = SharedConfig.ldcfg(defaults: testDefaults)
        XCTAssertTrue(loaded.companion.enabled)
        XCTAssertEqual(loaded.companion.host, "100.88.99.1")
        XCTAssertEqual(loaded.companion.port, 52099)
        XCTAssertEqual(loaded.companion.workMode, .fullKeyboard)
        XCTAssertEqual(loaded.companion.targetOS, .windows)
        XCTAssertEqual(loaded.companion.pulseDurationMs, 40)

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
