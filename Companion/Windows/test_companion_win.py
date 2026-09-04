#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MagicBoard Windows 伴侣服务自动化测试套件

涵盖:
1. 协议编解码与边界校验 (MBCP v1 16 字节大端协议)
2. USB HID Usage (Page 0x07) 到 Windows Virtual-Key / 扫描码映射完整性
3. Windows 键盘注入器状态机逻辑 (KeyDown / KeyUp / Pulse / 8 位修饰键增量同步)
4. 1.5 秒断网超时防卡键看门狗自动安全释放测试
5. ResetAll 紧急重置按键与修饰键测试
6. Live UDP 真实网络报文注入测试 (Win, Alt, Ctrl, Shift, Esc, Tab, F1~F12, Pulse, Watchdog)
"""

import sys
import os
import time
import struct
import socket
import unittest

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# 将当前目录加入模块路径以导入伴侣脚本逻辑
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

import magicboard_companion as comp


class TestWindowsCompanionProtocol(unittest.TestCase):
    """1. 协议报文编解码与边界测试"""

    def test_packet_structure_and_endianness(self):
        # 组装一个 KeyDown 报文: Win+Tab (MOD_L_CMD | Tab)
        magic = comp.MAGIC
        version = 1
        action = comp.ACTION_KEY_DOWN
        mods = comp.MOD_L_CMD  # 0x08
        flags = 0
        hid_usage = 0x002B     # Tab
        param = 0
        seq = 1001

        raw = struct.pack(comp.PACKET_FORMAT, magic, version, action, mods, flags, hid_usage, param, seq)
        self.assertEqual(len(raw), 16)

        # 验证大端魔数 "MBCP"
        self.assertEqual(raw[0:4], b"MBCP")

        # 解包验证
        u_magic, u_ver, u_act, u_mods, u_flags, u_hid, u_param, u_seq = struct.unpack(comp.PACKET_FORMAT, raw)
        self.assertEqual(u_magic, comp.MAGIC)
        self.assertEqual(u_ver, 1)
        self.assertEqual(u_act, comp.ACTION_KEY_DOWN)
        self.assertEqual(u_mods, comp.MOD_L_CMD)
        self.assertEqual(u_hid, 0x002B)
        self.assertEqual(u_seq, 1001)

    def test_all_action_types(self):
        actions = [
            comp.ACTION_KEY_DOWN,
            comp.ACTION_KEY_UP,
            comp.ACTION_PULSE,
            comp.ACTION_HEARTBEAT,
            comp.ACTION_RESET_ALL,
        ]
        for act in actions:
            raw = struct.pack(comp.PACKET_FORMAT, comp.MAGIC, 1, act, 0, 0, 0x0004, 50, 1)
            u = struct.unpack(comp.PACKET_FORMAT, raw)
            self.assertEqual(u[2], act)


class TestWindowsHIDMapping(unittest.TestCase):
    """2. USB HID Usage 到 Windows VK 映射完整性测试"""

    def test_letters_a_z(self):
        for i in range(26):
            hid = 0x0004 + i
            vk = comp.HID_TO_VK.get(hid)
            self.assertIsNotNone(vk, f"Letter HID 0x{hid:04X} should be mapped")
            self.assertEqual(vk, ord('A') + i)

    def test_digits_0_9(self):
        for i in range(9):
            hid = 0x001E + i
            vk = comp.HID_TO_VK.get(hid)
            self.assertEqual(vk, ord('1') + i)
        self.assertEqual(comp.HID_TO_VK.get(0x0027), ord('0'))

    def test_function_keys_f1_f12(self):
        for i in range(12):
            hid = 0x003A + i
            vk = comp.HID_TO_VK.get(hid)
            self.assertEqual(vk, comp.VK_F1 + i, f"F{i+1} VK mismatch")

    def test_core_controls_and_navigation(self):
        self.assertEqual(comp.HID_TO_VK.get(0x0028), comp.VK_RETURN)
        self.assertEqual(comp.HID_TO_VK.get(0x0029), comp.VK_ESCAPE)
        self.assertEqual(comp.HID_TO_VK.get(0x002A), comp.VK_BACK)
        self.assertEqual(comp.HID_TO_VK.get(0x002B), comp.VK_TAB)
        self.assertEqual(comp.HID_TO_VK.get(0x002C), comp.VK_SPACE)

        # 箭头导航
        self.assertEqual(comp.HID_TO_VK.get(0x004F), comp.VK_RIGHT)
        self.assertEqual(comp.HID_TO_VK.get(0x0050), comp.VK_LEFT)
        self.assertEqual(comp.HID_TO_VK.get(0x0051), comp.VK_DOWN)
        self.assertEqual(comp.HID_TO_VK.get(0x0052), comp.VK_UP)

    def test_modifiers_mapping(self):
        self.assertEqual(comp.HID_TO_VK.get(0x00E0), comp.VK_LCONTROL)
        self.assertEqual(comp.HID_TO_VK.get(0x00E1), comp.VK_LSHIFT)
        self.assertEqual(comp.HID_TO_VK.get(0x00E2), comp.VK_LMENU)
        self.assertEqual(comp.HID_TO_VK.get(0x00E3), comp.VK_LWIN)
        self.assertEqual(comp.HID_TO_VK.get(0x00E4), comp.VK_RCONTROL)
        self.assertEqual(comp.HID_TO_VK.get(0x00E5), comp.VK_RSHIFT)
        self.assertEqual(comp.HID_TO_VK.get(0x00E6), comp.VK_RMENU)
        self.assertEqual(comp.HID_TO_VK.get(0x00E7), comp.VK_RWIN)

    def test_extended_vks(self):
        # 验证 Win 键与箭头等包含在 Extended 集合中
        self.assertIn(comp.VK_LWIN, comp.EXTENDED_VKS)
        self.assertIn(comp.VK_RWIN, comp.EXTENDED_VKS)
        self.assertIn(comp.VK_LEFT, comp.EXTENDED_VKS)
        self.assertIn(comp.VK_RIGHT, comp.EXTENDED_VKS)
        self.assertIn(comp.VK_UP, comp.EXTENDED_VKS)
        self.assertIn(comp.VK_DOWN, comp.EXTENDED_VKS)


class TestWindowsInjectorState(unittest.TestCase):
    """3. 键盘注入器状态机、脉冲、看门狗与复位测试"""

    def setUp(self):
        self.injector = comp.WindowsKeyboardInjector(mock_mode=True)

    def test_keydown_keyup_tracking(self):
        vk_a = ord('A')
        self.injector.inject_key(vk_a, True, 0)
        self.assertIn(vk_a, self.injector.active_keys)

        self.injector.inject_key(vk_a, False, 0)
        self.assertNotIn(vk_a, self.injector.active_keys)

    def test_modifier_sync(self):
        # 模拟按下 Ctrl+Alt+Win
        mods = comp.MOD_L_CTRL | comp.MOD_L_OPT | comp.MOD_L_CMD
        self.injector.inject_key(ord('C'), True, mods)

        self.assertEqual(self.injector.active_modifiers, mods)
        # 验证历史记录中有 LCtrl, LAlt, LWin 的按下记录
        vks_injected = [item[0] for item in self.injector.injected_history if item[1] is True]
        self.assertIn(comp.VK_LCONTROL, vks_injected)
        self.assertIn(comp.VK_LMENU, vks_injected)
        self.assertIn(comp.VK_LWIN, vks_injected)
        self.assertIn(ord('C'), vks_injected)

        # 释放修饰键
        self.injector.inject_key(ord('C'), False, 0)
        self.assertEqual(self.injector.active_modifiers, 0)
        vks_released = [item[0] for item in self.injector.injected_history if item[1] is False]
        self.assertIn(comp.VK_LCONTROL, vks_released)
        self.assertIn(comp.VK_LMENU, vks_released)
        self.assertIn(comp.VK_LWIN, vks_released)
        self.assertIn(ord('C'), vks_released)

    def test_pulse_action(self):
        vk_tab = comp.VK_TAB
        self.injector.inject_pulse(vk_tab, duration_ms=20, mods=0)
        self.assertIn(vk_tab, self.injector.active_keys)

        # 等待脉冲持续时间结束
        time.sleep(0.06)
        self.assertNotIn(vk_tab, self.injector.active_keys)

    def test_reset_all(self):
        # 模拟多个按键悬空
        self.injector.active_keys.add(ord('X'))
        self.injector.active_keys.add(ord('Y'))
        self.injector.active_modifiers = comp.MOD_L_CTRL | comp.MOD_L_SHIFT

        self.injector.reset_all(reason="测试单元重置")
        self.assertEqual(len(self.injector.active_keys), 0)
        self.assertEqual(self.injector.active_modifiers, 0)

    def test_watchdog_timeout_auto_reset(self):
        # 模拟一个按键按下，随后网络断开超过 1.5 秒
        self.injector.active_keys.add(ord('W'))
        self.injector.last_packet_time = time.time() - 2.0  # 倒退 2 秒

        self.injector.check_watchdog()
        # 应该触发 reset_all，清空 active_keys
        self.assertEqual(len(self.injector.active_keys), 0)


def send_udp_packet(host: str, port: int, action: int, hid: int, mods: int = 0, param: int = 0, seq: int = 1):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    pkt = struct.pack(comp.PACKET_FORMAT, comp.MAGIC, comp.VERSION, action, mods, 0, hid, param, seq)
    sock.sendto(pkt, (host, port))
    sock.close()


def run_live_udp_suite(host="127.0.0.1", port=52088):
    """向正在运行的伴侣服务发送一套全面的测试报文"""
    print(f"\n📡 开始执行 Windows 伴侣 Live UDP 报文实测目标 -> {host}:{port} ...")

    # 1. 测试 Win 键 (Pulse 50ms)
    print("  [1/8] 测试 Win 键 Pulse (HID 0x00E3)...")
    send_udp_packet(host, port, comp.ACTION_PULSE, 0x00E3, param=50, seq=101)
    time.sleep(0.1)

    # 2. 测试 Esc 键 (Pulse 50ms - 关闭开始菜单)
    print("  [2/8] 测试 Escape 键 Pulse (HID 0x0029)...")
    send_udp_packet(host, port, comp.ACTION_PULSE, 0x0029, param=50, seq=102)
    time.sleep(0.1)

    # 3. 测试 Tab 键与 Alt+Tab 组合
    print("  [3/8] 测试 Tab 键与 Alt+Tab 组合 (HID 0x002B, Mods 0x04)...")
    send_udp_packet(host, port, comp.ACTION_KEY_DOWN, 0x002B, mods=comp.MOD_L_OPT, seq=103)
    time.sleep(0.05)
    send_udp_packet(host, port, comp.ACTION_KEY_UP, 0x002B, mods=0, seq=104)
    time.sleep(0.1)

    # 4. 测试 Control、Shift 修饰键
    print("  [4/8] 测试 Ctrl、Shift 独立按下与释放...")
    send_udp_packet(host, port, comp.ACTION_KEY_DOWN, 0x00E0, seq=105) # LCtrl
    time.sleep(0.03)
    send_udp_packet(host, port, comp.ACTION_KEY_UP, 0x00E0, seq=106)
    send_udp_packet(host, port, comp.ACTION_KEY_DOWN, 0x00E1, seq=107) # LShift
    time.sleep(0.03)
    send_udp_packet(host, port, comp.ACTION_KEY_UP, 0x00E1, seq=108)

    # 5. 测试功能键 F1 ~ F12
    print("  [5/8] 测试功能键 F1 ~ F12 脉冲注入...")
    for i in range(12):
        hid_f = 0x003A + i
        send_udp_packet(host, port, comp.ACTION_PULSE, hid_f, param=20, seq=200 + i)
        time.sleep(0.02)

    # 6. 测试普通按键与空格
    print("  [6/8] 测试 Space、Enter、Backspace 脉冲...")
    for hid in [0x002C, 0x0028, 0x002A]:
        send_udp_packet(host, port, comp.ACTION_PULSE, hid, param=20, seq=300 + hid)
        time.sleep(0.02)

    # 7. 测试 Heartbeat 心跳与 ResetAll 紧急重置
    print("  [7/8] 测试 Heartbeat 状态同步与 ResetAll 紧急重置...")
    send_udp_packet(host, port, comp.ACTION_HEARTBEAT, 0, mods=comp.MOD_L_CTRL, seq=401)
    time.sleep(0.05)
    send_udp_packet(host, port, comp.ACTION_RESET_ALL, 0, seq=402)
    time.sleep(0.1)

    # 8. 测试 1.5s 看门狗超时自动释放
    print("  [8/8] 测试 1.5s 防卡键看门狗超时机制 (发送 KeyDown 后停止发送 1.6 秒)...")
    send_udp_packet(host, port, comp.ACTION_KEY_DOWN, 0x0004, seq=501) # Key 'A' Down
    time.sleep(1.6) # 等待看门狗超时自动释放

    print("🎉 Live UDP 测试报文已全部成功发送！\n")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Windows Companion Test Suite")
    parser.add_argument("--unit-tests", action="store_true", help="运行单元测试")
    parser.add_argument("--live", action="store_true", help="发送真实 UDP 测试报文")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="目标主机地址 (默认 127.0.0.1)")
    parser.add_argument("--port", type=int, default=52088, help="目标 UDP 端口 (默认 52088)")
    args, unknown = parser.parse_known_args()

    if args.live:
        run_live_udp_suite(host=args.host, port=args.port)
    else:
        # 默认运行单元测试
        unittest.main(argv=[sys.argv[0]] + unknown)
