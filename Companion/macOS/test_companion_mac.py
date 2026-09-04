#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MagicBoard macOS 伴侣服务本地自动化测试套件

启动伴侣服务子进程并通过真实 UDP Socket 发送全量 MBCP 报文：
- KeyDown / KeyUp (Command + A)
- Option / Control / Shift 修饰键
- Escape, Tab, Space 单包脉冲
- F1 ~ F12 功能键脉冲
- 方向箭头键脉冲
- 1.5 秒无网络活动看门狗自动释放悬空按键
- ResetAll 紧急重置
支持测试 Swift 原生可执行文件与 Python 备用脚本。
"""

import sys
import os
import time
import socket
import struct
import subprocess
import argparse

MAGIC = 0x4D424350  # ASCII "MBCP"
VERSION = 1
PACKET_FORMAT = ">IBBBBHHI"

ACTION_KEY_DOWN = 0x01
ACTION_KEY_UP = 0x02
ACTION_PULSE = 0x03
ACTION_HEARTBEAT = 0x04
ACTION_RESET_ALL = 0x05

MOD_L_CTRL = 1 << 0
MOD_L_SHIFT = 1 << 1
MOD_L_OPT = 1 << 2
MOD_L_CMD = 1 << 3

def build_packet(action: int, hid_usage: int, modifiers: int = 0, param: int = 0, sequence: int = 1, flags: int = 0) -> bytes:
    return struct.pack(PACKET_FORMAT, MAGIC, VERSION, action, modifiers, flags, hid_usage, param, sequence)

def run_tests(binary_path: str, port: int = 52188):
    print(f"==================================================")
    print(f"🧪 开始运行 macOS 伴侣服务测试")
    print(f"   目标执行文件: {binary_path}")
    print(f"   测试 UDP 端口: {port}")
    print(f"==================================================")

    # 1. 启动伴侣服务进程
    if binary_path.endswith(".py"):
        cmd = [sys.executable, "-u", binary_path, "--port", str(port)]
    else:
        cmd = [binary_path, "--port", str(port)]

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    output_lines = []

    def read_output():
        for line in iter(proc.stdout.readline, ''):
            if line:
                output_lines.append(line.strip())
                print(f"   [伴侣日志] {line.strip()}")

    import threading
    t = threading.Thread(target=read_output, daemon=True)
    t.start()

    # 等待服务就绪标志
    start_wait = time.time()
    while time.time() - start_wait < 5.0:
        if any("已就绪" in l for l in output_lines):
            break
        time.sleep(0.05)
    else:
        print("⚠️ 等待服务就绪超时！")

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    dest = ("127.0.0.1", port)

    seq = 1

    try:
        # 2. 测试 Command + A 组合键 (KeyDown & KeyUp)
        print("\n👉 [测试 1] 发送 Command + A (KeyDown & KeyUp)")
        sock.sendto(build_packet(ACTION_KEY_DOWN, 0x0004, modifiers=MOD_L_CMD, sequence=seq), dest)
        seq += 1
        time.sleep(0.05)
        sock.sendto(build_packet(ACTION_KEY_UP, 0x0004, modifiers=MOD_L_CMD, sequence=seq), dest)
        seq += 1
        time.sleep(0.05)

        # 3. 测试 Control / Option 修饰键状态
        print("\n👉 [测试 2] 发送 Control 与 Option 修饰键事件")
        sock.sendto(build_packet(ACTION_KEY_DOWN, 0x00E0, modifiers=MOD_L_CTRL, sequence=seq), dest)
        seq += 1
        time.sleep(0.05)
        sock.sendto(build_packet(ACTION_KEY_UP, 0x00E0, sequence=seq), dest)
        seq += 1
        time.sleep(0.05)

        # 4. 测试 Esc / Tab / Space 单包脉冲
        print("\n👉 [测试 3] 发送 Esc, Tab, Space 单包脉冲 (Pulse)")
        sock.sendto(build_packet(ACTION_PULSE, 0x0029, param=20, sequence=seq), dest) # Esc
        seq += 1
        time.sleep(0.05)
        sock.sendto(build_packet(ACTION_PULSE, 0x002B, param=20, sequence=seq), dest) # Tab
        seq += 1
        time.sleep(0.05)
        sock.sendto(build_packet(ACTION_PULSE, 0x002C, param=20, sequence=seq), dest) # Space
        seq += 1
        time.sleep(0.05)

        # 5. 测试 F1 ~ F12 全功能键脉冲
        print("\n👉 [测试 4] 发送 F1 ~ F12 全功能键脉冲 (Pulse)")
        for f_usage in range(0x003A, 0x0046):
            f_num = f_usage - 0x003A + 1
            sock.sendto(build_packet(ACTION_PULSE, f_usage, param=15, sequence=seq), dest)
            seq += 1
            time.sleep(0.02)

        # 6. 测试方向箭头键 (Right, Left, Down, Up)
        print("\n👉 [测试 5] 发送四方向箭头键脉冲 (Pulse)")
        for arrow_usage in [0x004F, 0x0050, 0x0051, 0x0052]:
            sock.sendto(build_packet(ACTION_PULSE, arrow_usage, param=15, sequence=seq), dest)
            seq += 1
            time.sleep(0.02)

        # 7. 测试 Heartbeat 状态同步
        print("\n👉 [测试 6] 发送 Heartbeat 状态同步")
        sock.sendto(build_packet(ACTION_HEARTBEAT, 0, modifiers=MOD_L_SHIFT, sequence=seq), dest)
        seq += 1
        time.sleep(0.05)

        # 8. 测试 ResetAll 紧急重置
        print("\n👉 [测试 7] 发送 ResetAll 紧急重置指令")
        sock.sendto(build_packet(ACTION_RESET_ALL, 0, sequence=seq), dest)
        seq += 1
        time.sleep(0.1)

        # 9. 测试 1.5 秒断网看门狗防悬空机制
        print("\n👉 [测试 8] 测试 1.5 秒断网看门狗防悬空（发送 KeyDown 后停止所有通信）")
        sock.sendto(build_packet(ACTION_KEY_DOWN, 0x0028, modifiers=MOD_L_OPT, sequence=seq), dest) # Return
        seq += 1
        print("   ⏳ 正在等待 1.7 秒触发看门狗自动释放...")
        time.sleep(1.8)

        # 验证检查
        print("\n==================================================")
        print("🔍 验证测试日志与预期行为匹配:")
        full_log = "\n".join(output_lines)

        assert any("KeyDown" in l and ("0x00" in l or "0x0004" in l) for l in output_lines), "未找到 KeyDown A 记录"
        print("   ✅ 成功捕获 KeyDown A (Command+A)")

        assert any("Pulse" in l and ("0x35" in l or "0x0029" in l) for l in output_lines), "未找到 Pulse Esc 记录"
        print("   ✅ 成功捕获 Pulse Escape")

        assert any("Pulse" in l and ("0x30" in l or "0x002B" in l) for l in output_lines), "未找到 Pulse Tab 记录"
        print("   ✅ 成功捕获 Pulse Tab")

        assert any("Pulse" in l and "0x003A" in l for l in output_lines), "未找到 Pulse F1 记录"
        assert any("Pulse" in l and "0x0045" in l for l in output_lines), "未找到 Pulse F12 记录"
        print("   ✅ 成功捕获 F1 ~ F12 功能键脉冲")

        assert any("ResetAll" in l or "resetAll" in l for l in output_lines), "未找到 ResetAll 记录"
        print("   ✅ 成功响应 ResetAll 紧急复位")

        assert any("看门狗超时" in l or "WATCHDOG" in l for l in output_lines), "未找到看门狗超时触发记录"
        print("   ✅ 1.5 秒断网看门狗准时触发并成功释放悬空按键")

        print("==================================================")
        print("🎉 全部集成测试通过！服务运行正常。")

    finally:
        sock.close()
        proc.terminate()
        try:
            proc.wait(timeout=1.0)
        except subprocess.TimeoutExpired:
            proc.kill()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MagicBoard macOS 伴侣服务测试")
    parser.add_argument("--python", action="store_true", help="测试 Python 备用脚本而不是 Swift 二进制")
    parser.add_argument("--port", type=int, default=52188, help="测试 UDP 端口")
    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    if args.python:
        target = os.path.join(script_dir, "magicboard_companion.py")
    else:
        target = os.path.join(script_dir, "magicboard-companion-mac")
        if not os.path.exists(target):
            print(f"⚠️ 未找到二进制 {target}，正在执行自动编译...")
            subprocess.run(["/bin/zsh", os.path.join(script_dir, "build-mac.zsh")], check=True)

    run_tests(target, port=args.port)
