#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MagicBoard Windows 备用伴侣服务（零外部依赖 Python 3 脚本）

使用 Windows 原生 user32.dll / shell32.dll 与纯标准库实现，无需任何 pip 安装。
监听来自 iPad 键盘端的 MBCP 二进制 UDP 报文并通过 SendInput API 注入系统键盘队列。
"""

import sys
import os
import time
import struct
import socket
import threading
import argparse
import subprocess

# 确保在 Windows 控制台 (GBK 默认编码) 下正确输出 UTF-8 字符与 Emoji，并开启行缓冲
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)

# 仅在 Windows 环境下导入 ctypes 与 wintypes
if os.name == "nt":
    import ctypes
    from ctypes import wintypes
else:
    # 允许在非 Windows (如 macOS/Linux) 上以 mock/测试模式导入进行协议测试
    ctypes = None
    wintypes = None

# ==============================================================================
# 1. 协议常量定义 (MBCP v1)
# ==============================================================================
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
MOD_L_OPT = 1 << 2   # Windows 对应 Alt
MOD_L_CMD = 1 << 3   # Windows 对应 Win
MOD_R_CTRL = 1 << 4
MOD_R_SHIFT = 1 << 5
MOD_R_OPT = 1 << 6   # Windows 对应 Alt
MOD_R_CMD = 1 << 7   # Windows 对应 Win

# ==============================================================================
# 2. Windows Virtual-Key (VK) 常量定义
# ==============================================================================
VK_BACK = 0x08
VK_TAB = 0x09
VK_RETURN = 0x0D
VK_PAUSE = 0x13
VK_CAPITAL = 0x14  # CapsLock
VK_ESCAPE = 0x1B
VK_SPACE = 0x20
VK_PRIOR = 0x21    # PageUp
VK_NEXT = 0x22     # PageDown
VK_END = 0x23
VK_HOME = 0x24
VK_LEFT = 0x25
VK_UP = 0x26
VK_RIGHT = 0x27
VK_DOWN = 0x28
VK_SNAPSHOT = 0x2C # PrintScreen
VK_INSERT = 0x2D
VK_DELETE = 0x2E

VK_LWIN = 0x5B
VK_RWIN = 0x5C
VK_APPS = 0x5D

VK_NUMPAD0 = 0x60
VK_NUMPAD1 = 0x61
VK_NUMPAD2 = 0x62
VK_NUMPAD3 = 0x63
VK_NUMPAD4 = 0x64
VK_NUMPAD5 = 0x65
VK_NUMPAD6 = 0x66
VK_NUMPAD7 = 0x67
VK_NUMPAD8 = 0x68
VK_NUMPAD9 = 0x69
VK_MULTIPLY = 0x6A
VK_ADD = 0x6B
VK_SEPARATOR = 0x6C
VK_SUBTRACT = 0x6D
VK_DECIMAL = 0x6E
VK_DIVIDE = 0x6F

VK_F1 = 0x70
VK_F2 = 0x71
VK_F3 = 0x72
VK_F4 = 0x73
VK_F5 = 0x74
VK_F6 = 0x75
VK_F7 = 0x76
VK_F8 = 0x77
VK_F9 = 0x78
VK_F10 = 0x79
VK_F11 = 0x7A
VK_F12 = 0x7B

VK_NUMLOCK = 0x90
VK_SCROLL = 0x91

VK_LSHIFT = 0xA0
VK_RSHIFT = 0xA1
VK_LCONTROL = 0xA2
VK_RCONTROL = 0xA3
VK_LMENU = 0xA4   # Left Alt
VK_RMENU = 0xA5   # Right Alt

VK_OEM_1 = 0xBA       # ;:
VK_OEM_PLUS = 0xBB    # =+
VK_OEM_COMMA = 0xBC   # ,<
VK_OEM_MINUS = 0xBD   # -_
VK_OEM_PERIOD = 0xBE  # .>
VK_OEM_2 = 0xBF       # /?
VK_OEM_3 = 0xC0       # `~
VK_OEM_4 = 0xDB       # [{
VK_OEM_5 = 0xDC       # \|
VK_OEM_6 = 0xDD       # ]}
VK_OEM_7 = 0xDE       # '"

# SendInput Flags
INPUT_KEYBOARD = 1
KEYEVENTF_EXTENDEDKEY = 0x0001
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_SCANCODE = 0x0008
MAPVK_VK_TO_VSC = 0

# 扩展键集合 (需附加 KEYEVENTF_EXTENDEDKEY 标志)
EXTENDED_VKS = {
    VK_LWIN, VK_RWIN, VK_APPS,
    VK_RCONTROL, VK_RMENU,
    VK_INSERT, VK_DELETE, VK_HOME, VK_END,
    VK_PRIOR, VK_NEXT, VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN,
    VK_NUMLOCK, VK_DIVIDE, VK_SNAPSHOT,
}

# ==============================================================================
# 3. USB HID Usage (Page 0x07) -> Windows Virtual-Key (VK) 映射表
# ==============================================================================
HID_TO_VK = {
    # 字母 A-Z (0x04 ~ 0x1D) -> 0x41 ~ 0x5A
    **{0x0004 + i: 0x41 + i for i in range(26)},

    # 数字 1-9 (0x1E ~ 0x26) -> 0x31 ~ 0x39
    **{0x001E + i: 0x31 + i for i in range(9)},
    0x0027: 0x30,  # 0

    # 常用控制键与标点
    0x0028: VK_RETURN,
    0x0029: VK_ESCAPE,
    0x002A: VK_BACK,
    0x002B: VK_TAB,
    0x002C: VK_SPACE,
    0x002D: VK_OEM_MINUS,   # -
    0x002E: VK_OEM_PLUS,    # =
    0x002F: VK_OEM_4,       # [
    0x0030: VK_OEM_6,       # ]
    0x0031: VK_OEM_5,       # \
    0x0033: VK_OEM_1,       # ;
    0x0034: VK_OEM_7,       # '
    0x0035: VK_OEM_3,       # `
    0x0036: VK_OEM_COMMA,   # ,
    0x0037: VK_OEM_PERIOD,  # .
    0x0038: VK_OEM_2,       # /
    0x0039: VK_CAPITAL,

    # 功能键 F1 - F12 (0x3A ~ 0x45)
    **{0x003A + i: VK_F1 + i for i in range(12)},

    # 导航与控制键
    0x0046: VK_SNAPSHOT,   # PrintScreen
    0x0047: VK_SCROLL,     # ScrollLock
    0x0048: VK_PAUSE,      # Pause
    0x0049: VK_INSERT,     # Insert
    0x004A: VK_HOME,       # Home
    0x004B: VK_PRIOR,      # PageUp
    0x004C: VK_DELETE,     # Delete
    0x004D: VK_END,        # End
    0x004E: VK_NEXT,       # PageDown
    0x004F: VK_RIGHT,      # Right Arrow
    0x0050: VK_LEFT,       # Left Arrow
    0x0051: VK_DOWN,       # Down Arrow
    0x0052: VK_UP,         # Up Arrow

    # 小键盘区
    0x0053: VK_NUMLOCK,
    0x0054: VK_DIVIDE,
    0x0055: VK_MULTIPLY,
    0x0056: VK_SUBTRACT,
    0x0057: VK_ADD,
    0x0058: VK_RETURN,     # Numpad Enter (带 extended 属性)
    0x0059: VK_NUMPAD1,
    0x005A: VK_NUMPAD2,
    0x005B: VK_NUMPAD3,
    0x005C: VK_NUMPAD4,
    0x005D: VK_NUMPAD5,
    0x005E: VK_NUMPAD6,
    0x005F: VK_NUMPAD7,
    0x0060: VK_NUMPAD8,
    0x0061: VK_NUMPAD9,
    0x0062: VK_NUMPAD0,
    0x0063: VK_DECIMAL,

    # 修饰键 (0xE0 ~ 0xE7)
    0x00E0: VK_LCONTROL,
    0x00E1: VK_LSHIFT,
    0x00E2: VK_LMENU,      # Left Alt
    0x00E3: VK_LWIN,       # Left Win
    0x00E4: VK_RCONTROL,
    0x00E5: VK_RSHIFT,
    0x00E6: VK_RMENU,      # Right Alt
    0x00E7: VK_RWIN,       # Right Win
}

# 修饰键掩码位与对应 VK 键对照表
MODIFIER_TABLE = [
    (MOD_L_CTRL, VK_LCONTROL),
    (MOD_L_SHIFT, VK_LSHIFT),
    (MOD_L_OPT, VK_LMENU),
    (MOD_L_CMD, VK_LWIN),
    (MOD_R_CTRL, VK_RCONTROL),
    (MOD_R_SHIFT, VK_RSHIFT),
    (MOD_R_OPT, VK_RMENU),
    (MOD_R_CMD, VK_RWIN),
]

# ==============================================================================
# 4. Windows SendInput 结构体与 ctypes 注入绑定
# ==============================================================================
if ctypes and os.name == "nt":
    class KEYBDINPUT(ctypes.Structure):
        _fields_ = [
            ("wVk", wintypes.WORD),
            ("wScan", wintypes.WORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
        ]

    class HARDWAREINPUT(ctypes.Structure):
        _fields_ = [
            ("uMsg", wintypes.DWORD),
            ("wParamL", wintypes.WORD),
            ("wParamH", wintypes.WORD),
        ]

    class MOUSEINPUT(ctypes.Structure):
        _fields_ = [
            ("dx", wintypes.LONG),
            ("dy", wintypes.LONG),
            ("mouseData", wintypes.DWORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
        ]

    class _INPUT_UNION(ctypes.Union):
        _fields_ = [
            ("mi", MOUSEINPUT),
            ("ki", KEYBDINPUT),
            ("hi", HARDWAREINPUT),
        ]

    class INPUT(ctypes.Structure):
        _anonymous_ = ("_u",)
        _fields_ = [
            ("type", wintypes.DWORD),
            ("_u", _INPUT_UNION),
        ]

    user32 = ctypes.windll.user32
    user32.SendInput.argtypes = [wintypes.UINT, ctypes.POINTER(INPUT), ctypes.c_int]
    user32.SendInput.restype = wintypes.UINT

    user32.MapVirtualKeyW.argtypes = [wintypes.UINT, wintypes.UINT]
    user32.MapVirtualKeyW.restype = wintypes.UINT

    shell32 = ctypes.windll.shell32
else:
    INPUT = None
    user32 = None
    shell32 = None


# ==============================================================================
# 5. 键盘注入器核心类
# ==============================================================================
class WindowsKeyboardInjector:
    def __init__(self, mock_mode=False):
        self.mock_mode = mock_mode or (user32 is None)
        self.lock = threading.Lock()
        self.active_keys = set()       # 记录处于按下状态的 VK 集合
        self.active_modifiers = 0      # 记录当前已生效的 8 位修饰键掩码
        self.last_packet_time = time.time()
        self.injected_history = []     # 供测试套件断言验证

    def _send_vk(self, vk: int, is_down: bool):
        """调用 Windows SendInput 注入单个 VK 键按下或释放"""
        scan = 0
        flags = 0
        if not is_down:
            flags |= KEYEVENTF_KEYUP
        if vk in EXTENDED_VKS:
            flags |= KEYEVENTF_EXTENDEDKEY

        if not self.mock_mode and user32:
            scan = user32.MapVirtualKeyW(vk, MAPVK_VK_TO_VSC)
            inp = INPUT()
            inp.type = INPUT_KEYBOARD
            inp.ki.wVk = vk
            inp.ki.wScan = scan
            inp.ki.dwFlags = flags
            inp.ki.time = 0
            inp.ki.dwExtraInfo = None
            user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))
        else:
            self.injected_history.append((vk, is_down, flags, scan))

    def _sync_modifiers(self, target_mods: int):
        """增量同步修饰键状态（根据 target_mods 与 active_modifiers 差异补发按下或释放）"""
        for mask_bit, vk in MODIFIER_TABLE:
            should_down = bool(target_mods & mask_bit)
            is_down = bool(self.active_modifiers & mask_bit)
            if should_down and not is_down:
                self._send_vk(vk, True)
            elif not should_down and is_down:
                self._send_vk(vk, False)
        self.active_modifiers = target_mods

    def inject_key(self, vk: int, is_down: bool, mods: int):
        """注入按键按下或抬起，并同步修饰键状态"""
        with self.lock:
            self.last_packet_time = time.time()
            self._sync_modifiers(mods)

            if is_down:
                self.active_keys.add(vk)
                self._send_vk(vk, True)
            else:
                self.active_keys.discard(vk)
                self._send_vk(vk, False)

    def inject_pulse(self, vk: int, duration_ms: int, mods: int):
        """执行单包脉冲按键（KeyDown -> 等待指定毫秒 -> KeyUp）"""
        dur_sec = max(5, min(duration_ms, 500)) / 1000.0

        with self.lock:
            self.last_packet_time = time.time()
            self._sync_modifiers(mods)
            self.active_keys.add(vk)
            self._send_vk(vk, True)

        def delayed_up():
            time.sleep(dur_sec)
            with self.lock:
                self.active_keys.discard(vk)
                self._send_vk(vk, False)

        t = threading.Thread(target=delayed_up, daemon=True)
        t.start()

    def sync_heartbeat(self, mods: int):
        """心跳报文状态同步"""
        with self.lock:
            self.last_packet_time = time.time()
            self._sync_modifiers(mods)

    def reset_all(self, reason="手动重置"):
        """紧急安全释放所有处于按下状态的按键与全部修饰键"""
        with self.lock:
            keys_to_release = list(self.active_keys)
            self.active_keys.clear()
            self.active_modifiers = 0
            self.last_packet_time = time.time()

        now = time.strftime("%H:%M:%S")
        print(f"[{now}] 🛡️ 执行 resetAll ({reason})，正在安全释放所有按键...")

        # 释放普通按键
        for vk in keys_to_release:
            self._send_vk(vk, False)

        # 释放全部 8 个修饰键
        for _, vk in MODIFIER_TABLE:
            self._send_vk(vk, False)

        print(f"[{now}] ✅ 所有按键与修饰键已全部复位释放。")

    def check_watchdog(self):
        """检查 1.5 秒无数据包超时，如有悬空按键则自动安全复位"""
        with self.lock:
            has_active = bool(self.active_keys) or (self.active_modifiers != 0)
            elapsed = time.time() - self.last_packet_time

        if has_active and elapsed >= 1.5:
            self.reset_all(reason=f"看门狗超时 (已超时 {elapsed:.2f} 秒)")


# ==============================================================================
# 6. Windows 提权与防火墙辅助工具函数
# ==============================================================================
def is_admin():
    """检查当前进程是否具有 Windows 管理员权限"""
    if os.name != "nt" or not shell32:
        return True
    try:
        return shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def elevate_process():
    """通过 UAC 提权重新拉起当前脚本运行"""
    if os.name != "nt" or not shell32:
        print("❌ 仅在 Windows 环境下支持 UAC 提权。")
        return False
    try:
        params = " ".join([f'"{arg}"' for arg in sys.argv])
        hinst = shell32.ShellExecuteW(None, "runas", sys.executable, params, None, 1)
        if hinst > 32:
            print("🚀 已成功请求 UAC 管理员提权并启动新实例，当前进程退出。")
            sys.exit(0)
        else:
            print(f"❌ UAC 提权请求未成功 (ShellExecute 错误码: {hinst})")
            return False
    except Exception as e:
        print(f"❌ 请求提权时发生异常: {e}")
        return False

def add_firewall_rule(port=52088):
    """添加 Windows 防火墙 UDP 端口放行规则"""
    rule_name = f"MagicBoard Companion UDP {port}"
    cmd = [
        "netsh", "advfirewall", "firewall", "add", "rule",
        f"name={rule_name}",
        "dir=in",
        "action=allow",
        "protocol=UDP",
        f"localport={port}"
    ]
    print(f"🔧 正在添加 Windows 防火墙规则: {' '.join(cmd)}")
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("✅ 防火墙规则添加成功:\n" + res.stdout.strip())
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 添加防火墙规则失败 (可能需要管理员权限): {e.stderr.strip()}")
        return False


# ==============================================================================
# 7. UDP 服务主循环
# ==============================================================================
class CompanionServer:
    def __init__(self, port=52088, mock_mode=False):
        self.port = port
        self.injector = WindowsKeyboardInjector(mock_mode=mock_mode)
        self.running = True
        self.sock = None

    def print_banner(self):
        print("=" * 64)
        print("🎹 MagicBoard Windows 伴侣服务 (Python 原生备用版)")
        print("   协议标准: MBCP v1 (UDP 16-Byte Binary Protocol)")
        print(f"   监听端口: UDP {self.port}")
        print("=" * 64)

        # UIPI 权限检测
        if not is_admin():
            print("⚠️ [警告] 当前未以管理员权限运行 (Non-Admin)！")
            print("   受 Windows UIPI 隔离限制，无法向管理员终端、任务管理器等提权窗口注入按键。")
            print("   👉 建议右键以“管理员身份运行”，或添加参数 --elevate 自动拉起 UAC 提权。")
        else:
            print("✅ 管理员权限检测通过 (Admin / High Integrity) - 突破 UIPI 隔离。")

        print("-" * 64)
        print("💡 防火墙配置指引 (若局域网无法连通):")
        print(f"   pwsh -Command \"New-NetFirewallRule -DisplayName 'MagicBoard Companion' -Direction Inbound -LocalPort {self.port} -Protocol UDP -Action Allow\"")
        print("=" * 64)

    def _watchdog_loop(self):
        while self.running:
            time.sleep(0.1)
            self.injector.check_watchdog()

    def handle_packet(self, data: bytes, addr):
        if len(data) != PACKET_LENGTH:
            print(f"⚠️ 丢弃非法长度报文: {len(data)} 字节 (来自 {addr})")
            return

        magic, version, action, mods, flags, hid_usage, param, seq = struct.unpack(PACKET_FORMAT, data)

        if magic != MAGIC:
            print(f"⚠️ 丢弃非法魔数报文: 0x{magic:08X} (来自 {addr})")
            return

        if version != VERSION:
            print(f"⚠️ 丢弃不支持协议版本: {version}")
            return

        now = time.strftime("%H:%M:%S")

        # 1. 紧急重置 ResetAll (0x05)
        if action == ACTION_RESET_ALL:
            print(f"[{now}] 🚨 收到 resetAll 指令 (seq: {seq})，执行安全复位")
            self.injector.reset_all(reason="收到 iPad 端 ResetAll 报文")
            return

        # 2. 心跳报文 Heartbeat (0x04)
        if action == ACTION_HEARTBEAT:
            self.injector.sync_heartbeat(mods)
            return

        # 解析 HID Usage 到 Windows VK
        vk = HID_TO_VK.get(hid_usage)
        if vk is None:
            print(f"[{now}] ⚠️ 未知或未映射的 HID Usage: 0x{hid_usage:04X} (seq: {seq})")
            return

        # 3. 按键按下 KeyDown (0x01)
        if action == ACTION_KEY_DOWN:
            print(f"[{now}] ⬇️ KeyDown: HID 0x{hid_usage:04X} -> VK 0x{vk:02X}, Mods: 0x{mods:02X}, Seq: {seq}")
            self.injector.inject_key(vk, True, mods)

        # 4. 按键抬起 KeyUp (0x02)
        elif action == ACTION_KEY_UP:
            print(f"[{now}] ⬆️ KeyUp:   HID 0x{hid_usage:04X} -> VK 0x{vk:02X}, Mods: 0x{mods:02X}, Seq: {seq}")
            self.injector.inject_key(vk, False, mods)

        # 5. 单包脉冲 Pulse (0x03)
        elif action == ACTION_PULSE:
            duration = param if param > 0 else 50
            print(f"[{now}] ⚡ Pulse:   HID 0x{hid_usage:04X} -> VK 0x{vk:02X}, 时长: {duration}ms, Mods: 0x{mods:02X}, Seq: {seq}")
            self.injector.inject_pulse(vk, duration, mods)

        else:
            print(f"[{now}] ⚠️ 未知 Action: 0x{action:02X} (seq: {seq})")

    def start(self):
        self.print_banner()

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(("0.0.0.0", self.port))

        print(f"🚀 MagicBoard Windows 伴侣服务已就绪，正在监听 UDP 端口 {self.port}...")
        print("💡 提示：按 Ctrl+C 可停止服务，iPad 键盘端输入时将实时捕获并注入。")

        # 启动 1.5s 防卡键看门狗
        watchdog_thread = threading.Thread(target=self._watchdog_loop, daemon=True)
        watchdog_thread.start()

        try:
            while self.running:
                data, addr = self.sock.recvfrom(1024)
                self.handle_packet(data, addr)
        except KeyboardInterrupt:
            print("\n🛑 收到退出信号，正在关闭伴侣服务...")
        finally:
            self.running = False
            self.injector.reset_all(reason="服务退出清理")
            if self.sock:
                self.sock.close()
            print("👋 MagicBoard 伴侣服务已安全终止。")


# ==============================================================================
# 8. 入口解析与主执行流程
# ==============================================================================
def main():
    parser = argparse.ArgumentParser(description="MagicBoard Windows 被控端伴侣服务 (Python 3 零依赖备用版)")
    parser.add_argument("--port", "-p", type=int, default=52088, help="UDP 监听端口 (默认 52088)")
    parser.add_argument("--elevate", "-e", action="store_true", help="如果未以管理员运行，自动请求 UAC 提权启动")
    parser.add_argument("--add-firewall", action="store_true", help="在 Windows 防火墙中自动添加入站放行规则并退出")
    parser.add_argument("--mock", action="store_true", help="模拟测试模式（不实际调用 Windows user32 API）")
    args = parser.parse_args()

    if args.add_firewall:
        success = add_firewall_rule(args.port)
        sys.exit(0 if success else 1)

    if args.elevate and not is_admin():
        elevate_process()

    server = CompanionServer(port=args.port, mock_mode=args.mock)
    server.start()

if __name__ == "__main__":
    main()
