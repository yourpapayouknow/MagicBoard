#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""iPad 模拟器与 macOS 伴侣服务端到端真实联动验证脚本

流程：
1. 在 macOS 本机启动伴侣服务子进程 (端口 52188)；
2. 调度 iOS 模拟器 (iPad Pro 12.9 2018) 执行针对性单元测试 testSimulatorToHostUDPSend；
3. iOS 模拟器内部的测试进程向 127.0.0.1:52188 发送真实 MBCP UDP 报文 (Pulse Esc, KeyDown/Up Cmd+A, Pulse F5)；
4. macOS 伴侣服务接收报文并转换为 CGKeyCode 注入 macOS 系统队列；
5. 验证双向通信成功与测试通过。
"""

import sys
import os
import time
import subprocess

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    binary_path = os.path.join(script_dir, "magicboard-companion-mac")
    port = 52188

    print("==================================================")
    print("🚀 启动 iPad 模拟器与 macOS 伴侣服务端到端联动验证")
    print(f"   macOS 伴侣端口: {port}")
    print("   iOS 模拟器目标: MagicBoard iPad Pro 12.9 2018")
    print("==================================================")

    # 1. 启动 macOS 伴侣服务
    proc = subprocess.Popen(
        [binary_path, "--port", str(port)],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    companion_logs = []

    def read_companion():
        for line in iter(proc.stdout.readline, ''):
            if line:
                companion_logs.append(line.strip())
                print(f"   [Mac 伴侣日志] {line.strip()}")

    import threading
    t = threading.Thread(target=read_companion, daemon=True)
    t.start()

    # 等待伴侣就绪
    start_time = time.time()
    while time.time() - start_time < 5.0:
        if any("已就绪" in l for l in companion_logs):
            break
        time.sleep(0.05)
    else:
        print("❌ 等待 Mac 伴侣服务启动超时！")
        proc.kill()
        sys.exit(1)

    print("\n📱 正在触发 iPad 模拟器内部进程发送测试报文...")

    # 2. 运行 iOS 模拟器测试
    test_cmd = [
        "xcodebuild", "test",
        "-scheme", "MagicBoardShared",
        "-destination", "platform=iOS Simulator,id=73860E49-6DDF-450B-B505-F0E0A09F764B",
        "-only-testing:MagicBoardSharedTests/CompanionProtocolTests/testSimulatorToHostUDPSend"
    ]

    sim_res = subprocess.run(
        test_cmd,
        cwd=os.path.join(project_root, "Packages/MagicBoardShared"),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    time.sleep(0.5)

    # 3. 停止伴侣服务
    proc.terminate()
    try:
        proc.wait(timeout=1.0)
    except subprocess.TimeoutExpired:
        proc.kill()

    print("\n==================================================")
    print("🔍 验证结果审查:")

    # 验证模拟器测试通过
    sim_passed = "** TEST SUCCEEDED **" in sim_res.stdout
    print(f"   1. iPad 模拟器内部测试状态: {'✅ 通过 (TEST SUCCEEDED)' if sim_passed else '❌ 失败'}")

    # 验证 Mac 伴侣接收到的真实报文
    received_esc = any("0x0029" in l and "Pulse" in l for l in companion_logs)
    received_a = any("0x0004" in l and "KeyDown" in l for l in companion_logs)
    received_f5 = any("0x003E" in l and "Pulse" in l for l in companion_logs)

    print(f"   2. Mac 伴侣接收到 iPad 发来的 Pulse Esc: {'✅ 成功' if received_esc else '❌ 缺失'}")
    print(f"   3. Mac 伴侣接收到 iPad 发来的 Command+A: {'✅ 成功' if received_a else '❌ 缺失'}")
    print(f"   4. Mac 伴侣接收到 iPad 发来的 Pulse F5:  {'✅ 成功' if received_f5 else '❌ 缺失'}")

    if sim_passed and received_esc and received_a and received_f5:
        print("==================================================")
        print("🎉 恭喜！iPad 模拟器与 macOS 伴侣服务端到端真实网络链路联动验证 100% 成功！")
    else:
        print("==================================================")
        print("❌ 联动验证存在未通过项，请查看上方日志。")
        sys.exit(1)

if __name__ == "__main__":
    main()
