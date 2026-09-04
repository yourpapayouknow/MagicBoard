#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MagicBoard macOS 备用伴侣服务（零外部依赖 Python 3 脚本）

使用 macOS 原生 CoreGraphics 动态库与纯标准库实现，无需任何 pip 安装。
监听来自 iPad 键盘端的 MBCP 二进制 UDP 报文并注入系统键盘事件队列。
"""

import sys
import os
import time
import struct
import socket
import threading
import argparse
import ctypes
import ctypes.util

# 协议常量
MAGIC = 0x4D424350  # ASCII "MBCP"
VERSION = 1
PACKET_LENGTH = 16
PACKET_FORMAT = ">IBBBBHHI"

ACTION_KEY_DOWN = 0x01
ACTION_KEY_UP = 0x02
ACTION_PULSE = 0x03
ACTION_HEARTBEAT = 0x04
ACTION_RESET_ALL = 0x05

# 8 位修饰键掩码
MOD_L_CTRL = 1 << 0
MOD_L_SHIFT = 1 << 1
MOD_L_OPT = 1 << 2
MOD_L_CMD = 1 << 3
MOD_R_CTRL = 1 << 4
MOD_R_SHIFT = 1 << 5
MOD_R_OPT = 1 << 6
MOD_R_CMD = 1 << 7

# CoreGraphics Event Flags
CG_FLAG_COMMAND = 0x00100000
CG_FLAG_SHIFT = 0x00020000
CG_FLAG_ALTERNATE = 0x00080000
CG_FLAG_CONTROL = 0x00040000

# USB HID Usage (Page 0x07) -> macOS CGKeyCode (kVK_*)
HID_TO_CGKEY = {
    # 字母 A-Z (0x04 ~ 0x1D)
    0x0004: 0x00,  # A
    0x0005: 0x0B,  # B
    0x0006: 0x08,  # C
    0x0007: 0x02,  # D
    0x0008: 0x0E,  # E
    0x0009: 0x03,  # F
    0x000A: 0x05,  # G
    0x000B: 0x04,  # H
    0x000C: 0x22,  # I
    0x000D: 0x26,  # J
    0x000E: 0x28,  # K
    0x000F: 0x25,  # L
    0x0010: 0x2E,  # M
    0x0011: 0x2D,  # N
    0x0012: 0x1F,  # O
    0x0013: 0x23,  # P
    0x0014: 0x0C,  # Q
    0x0015: 0x0F,  # R
    0x0016: 0x01,  # S
    0x0017: 0x11,  # T
    0x0018: 0x20,  # U
    0x0019: 0x09,  # V
    0x001A: 0x0D,  # W
    0x001B: 0x07,  # X
    0x001C: 0x10,  # Y
    0x001D: 0x06,  # Z

    # 数字 1-0 (0x1E ~ 0x27)
    0x001E: 0x12,  # 1
    0x001F: 0x13,  # 2
    0x0020: 0x14,  # 3
    0x0021: 0x15,  # 4
    0x0022: 0x17,  # 5
    0x0023: 0x16,  # 6
    0x0024: 0x1A,  # 7
    0x0025: 0x1C,  # 8
    0x0026: 0x19,  # 9
    0x0027: 0x1D,  # 0

    # 常用控制键与符号
    0x0028: 0x24,  # Return / Enter
    0x0029: 0x35,  # Escape
    0x002A: 0x33,  # Delete / Backspace
    0x002B: 0x30,  # Tab
    0x002C: 0x31,  # Spacebar
    0x002D: 0x1B,  # Minus (-)
    0x002E: 0x18,  # Equal (=)
    0x002F: 0x21,  # Open Bracket ([)
    0x0030: 0x1E,  # Close Bracket (])
    0x0031: 0x2A,  # Backslash (\)
    0x0033: 0x29,  # Semicolon (;)
    0x0034: 0x27,  # Quote (')
    0x0035: 0x32,  # Grave (`)
    0x0036: 0x2B,  # Comma (,)
    0x0037: 0x2F,  # Period (.)
    0x0038: 0x2C,  # Slash (/)
    0x0039: 0x39,  # CapsLock

    # 功能键 F1 - F12 (0x3A ~ 0x45)
    0x003A: 0x7A,  # F1
    0x003B: 0x78,  # F2
    0x003C: 0x63,  # F3
    0x003D: 0x76,  # F4
    0x003E: 0x60,  # F5
    0x003F: 0x61,  # F6
    0x0040: 0x62,  # F7
    0x0041: 0x64,  # F8
    0x0042: 0x65,  # F9
    0x0043: 0x6D,  # F10
    0x0044: 0x67,  # F11
    0x0045: 0x6F,  # F12

    # 导航键与箭头
    0x0046: 0x69,  # PrintScreen
    0x0047: 0x6B,  # ScrollLock
    0x0048: 0x71,  # Pause
    0x0049: 0x72,  # Insert (Help)
    0x004A: 0x73,  # Home
    0x004B: 0x74,  # PageUp
    0x004C: 0x75,  # Delete Forward
    0x004D: 0x77,  # End
    0x004E: 0x79,  # PageDown
    0x004F: 0x7C,  # Right Arrow
    0x0050: 0x7B,  # Left Arrow
    0x0051: 0x7D,  # Down Arrow
    0x0052: 0x7E,  # Up Arrow

    # 修饰键 (0xE0 ~ 0xE7)
    0x00E0: 0x3B,  # Left Control
    0x00E1: 0x38,  # Left Shift
    0x00E2: 0x3A,  # Left Option
    0x00E3: 0x37,  # Left Command
    0x00E4: 0x3E,  # Right Control
    0x00E5: 0x3C,  # Right Shift
    0x00E6: 0x3D,  # Right Option
    0x00E7: 0x36,  # Right Command
}

# 动态加载 macOS 系统动态库
def load_macos_frameworks():
    try:
        cg = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
        cf = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
        ax = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices")
    except OSError as e:
        print(f"❌ 无法加载 macOS 系统框架: {e}")
        sys.exit(1)

    cg.CGEventSourceCreate.argtypes = [ctypes.c_int32]
    cg.CGEventSourceCreate.restype = ctypes.c_void_p

    cg.CGEventCreateKeyboardEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint16, ctypes.c_bool]
    cg.CGEventCreateKeyboardEvent.restype = ctypes.c_void_p

    cg.CGEventSetFlags.argtypes = [ctypes.c_void_p, ctypes.c_uint64]
    cg.CGEventSetFlags.restype = None

    cg.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
    cg.CGEventPost.restype = None

    cf.CFRelease.argtypes = [ctypes.c_void_p]
    cf.CFRelease.restype = None

    ax.AXIsProcessTrusted.argtypes = []
    ax.AXIsProcessTrusted.restype = ctypes.c_bool

    return cg, cf, ax

cg, cf, ax = load_macos_frameworks()

class KeyboardInjector:
    def __init__(self):
        # 1 = kCGEventSourceStateHIDSystemState
        self.source = cg.CGEventSourceCreate(1)
        self.lock = threading.Lock()
        self.active_keys = set()
        self.active_modifiers = 0
        self.last_packet_time = time.time()

    def get_cg_flags(self, mods: int) -> int:
        flags = 0
        if mods & (MOD_L_CMD | MOD_R_CMD):
            flags |= CG_FLAG_COMMAND
        if mods & (MOD_L_OPT | MOD_R_OPT):
            flags |= CG_FLAG_ALTERNATE
        if mods & (MOD_L_CTRL | MOD_R_CTRL):
            flags |= CG_FLAG_CONTROL
        if mods & (MOD_L_SHIFT | MOD_R_SHIFT):
            flags |= CG_FLAG_SHIFT
        return flags

    def inject_key(self, code: int, is_down: bool, mods: int):
        with self.lock:
            self.last_packet_time = time.time()
            if is_down:
                self.active_keys.add(code)
            else:
                self.active_keys.discard(code)
            self.active_modifiers = mods

        flags = self.get_cg_flags(mods)
        event = cg.CGEventCreateKeyboardEvent(self.source, code, is_down)
        if event:
            cg.CGEventSetFlags(event, flags)
            # 0 = kCGHIDEventTap
            cg.CGEventPost(0, event)
            cf.CFRelease(event)

    def inject_pulse(self, code: int, duration_ms: int, mods: int):
        dur = max(5, min(duration_ms, 500)) / 1000.0
        self.inject_key(code, True, mods)

        def delayed_up():
            time.sleep(dur)
            self.inject_key(code, False, mods)

        t = threading.Thread(target=delayed_up, daemon=True)
        t.start()

    def sync_heartbeat(self, mods: int):
        with self.lock:
            self.last_packet_time = time.time()
            self.active_modifiers = mods

    def reset_all(self, reason="手动重置"):
        with self.lock:
            keys_to_release = list(self.active_keys)
            self.active_keys.clear()
            self.active_modifiers = 0
            self.last_packet_time = time.time()

        now = time.strftime("%H:%M:%S")
        print(f"[{now}] 🛡️ 执行 resetAll ({reason})，正在安全释放所有按键...")

        for code in keys_to_release:
            event = cg.CGEventCreateKeyboardEvent(self.source, code, False)
            if event:
                cg.CGEventSetFlags(event, 0)
                cg.CGEventPost(0, event)
                cf.CFRelease(event)

        # 释放所有修饰键
        mod_keys = [0x37, 0x36, 0x3A, 0x3D, 0x3B, 0x3E, 0x38, 0x3C]
        for mk in mod_keys:
            event = cg.CGEventCreateKeyboardEvent(self.source, mk, False)
            if event:
                cg.CGEventSetFlags(event, 0)
                cg.CGEventPost(0, event)
                cf.CFRelease(event)

        print(f"[{now}] ✅ 所有按键与修饰键已全部复位释放。")

    def check_watchdog(self):
        with self.lock:
            has_active = bool(self.active_keys) or (self.active_modifiers != 0)
            elapsed = time.time() - self.last_packet_time

        if has_active and elapsed >= 1.5:
            self.reset_all(reason=f"看门狗超时 (已超时 {elapsed:.2f} 秒)")

class CompanionServer:
    def __init__(self, port=52088):
        self.port = port
        self.injector = KeyboardInjector()
        self.running = True
        self.sock = None

    def start(self):
        self.print_banner()

        # 辅助功能检测
        if not ax.AXIsProcessTrusted():
            print("⚠️ [警告] 当前进程缺少 macOS 辅助功能 (Accessibility) 权限！")
            print("   键盘事件注入可能无法生效。")
            print("   👉 请在 [系统设置 -> 隐私与安全性 -> 辅助功能] 中允许当前终端或 Python 解释器。")
        else:
            print("✅ 辅助功能权限验证通过 (Accessibility Trusted)。")

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(("0.0.0.0", self.port))

        print(f"🚀 MagicBoard Python 伴侣服务已就绪，正在监听 UDP 端口 {self.port}...")
        print("💡 提示：按 Ctrl+C 可停止服务，iPad 键盘端输入时将实时捕获并注入。")

        # 启动看门狗线程
        watchdog_thread = threading.Thread(target=self._watchdog_loop, daemon=True)
        watchdog_thread.start()

        # 主循环
        try:
            while self.running:
                data, addr = self.sock.recvfrom(256)
                if len(data) < PACKET_LENGTH:
                    continue
                self.handle_packet(data)
        except KeyboardInterrupt:
            print("\n🛑 正在停止伴侣服务...")
            self.injector.reset_all(reason="服务退出")
        finally:
            if self.sock:
                self.sock.close()

    def _watchdog_loop(self):
        while self.running:
            time.sleep(0.2)
            self.injector.check_watchdog()

    def handle_packet(self, data: bytes):
        magic, version, action, modifiers, flags, hid_usage, param, sequence = struct.unpack(PACKET_FORMAT, data[:16])
        if magic != MAGIC or version != VERSION:
            return

        now = time.strftime("%H:%M:%S")

        if action == ACTION_KEY_DOWN:
            code = HID_TO_CGKEY.get(hid_usage)
            if code is not None:
                print(f"[{now}] ⬇️ KeyDown: HID 0x{hid_usage:04X} -> CGKey 0x{code:02X} (seq: {sequence}, mods: {modifiers})")
                self.injector.inject_key(code, True, modifiers)
            else:
                print(f"[{now}] ⚠️ 未知 HID Usage 0x{hid_usage:04X}")

        elif action == ACTION_KEY_UP:
            code = HID_TO_CGKEY.get(hid_usage)
            if code is not None:
                print(f"[{now}] ⬆️ KeyUp: HID 0x{hid_usage:04X} -> CGKey 0x{code:02X} (seq: {sequence})")
                self.injector.inject_key(code, False, modifiers)

        elif action == ACTION_PULSE:
            code = HID_TO_CGKEY.get(hid_usage)
            if code is not None:
                dur = param if param > 0 else 20
                print(f"[{now}] ⚡ Pulse: HID 0x{hid_usage:04X} -> CGKey 0x{code:02X} ({dur}ms, seq: {sequence}, mods: {modifiers})")
                self.injector.inject_pulse(code, dur, modifiers)

        elif action == ACTION_HEARTBEAT:
            self.injector.sync_heartbeat(modifiers)

        elif action == ACTION_RESET_ALL:
            self.injector.reset_all(reason="收到客户端 ResetAll 指令")

    def print_banner(self):
        print(f"""
============================================================
   ✨ MagicBoard Companion Server (macOS Python 零依赖版) ✨
   协议: MBCP v1 (16-byte UDP) | 端口: {self.port}
   看门狗超时: 1.5 秒 | 注入引擎: CoreGraphics (ctypes)
============================================================
""")

def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(line_buffering=True)

    parser = argparse.ArgumentParser(description="MagicBoard macOS 备用伴侣服务")
    parser.add_argument("-p", "--port", type=int, default=52088, help="指定 UDP 监听端口 (默认: 52088)")
    args = parser.parse_args()

    server = CompanionServer(port=args.port)
    server.start()

if __name__ == "__main__":
    main()
