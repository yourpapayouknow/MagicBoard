# MagicBoard Companion Protocol (MBCP) 规范说明书

## 1. 概述与设计哲学

MagicBoard Companion Protocol（MBCP）是专为 MagicBoard 打造的**无状态、超低延迟、定长二进制 UDP 通信协议**。
用于将 iPad 键盘端产生的功能键、组合快捷键（或全键盘动作）通过局域网以亚毫秒级（<1ms）开销分流至远端被控计算机（macOS / Windows 伴侣服务）。

### 核心特性
- **固定 16 字节报文**：避免动态内存分配、无变长分片边界问题，跨语言解析零开销。
- **纯无状态设计**：UDP 单向轻量级投递，无需建立握手连接与 TCP 拥塞控制等待，兼顾最低延迟。
- **抗悬空脉冲（Pulse）**：支持单包脉冲按键（伴侣服务收到后自动执行按下并延时抬起），在弱网 UDP 偶发丢包时杜绝按键悬空卡死。
- **状态同步与心跳（Heartbeat）**：定期同步修饰键（Ctrl / Shift / Alt / Win）状态与探活，支持伴侣端看门狗自动安全复位。
- **紧急重置（ResetAll）**：一键安全释放被控端所有按键。
- **国际标准 16 位 USB HID Usage**：基于 USB HID Usage Tables (Page 0x07)，天然跨平台统一。

---

## 2. 报文帧结构（16 字节网络大端序）

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       Magic: "MBCP" (0x4D424350)              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Version (1)  |  Action (u8)  | Modifiers(u8) |   Flags (u8)  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|       HID Usage (u16)         |     Param / Duration (u16)    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       Sequence (u32)                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### 字段定义说明

| 字节偏移 | 字段名 | 类型 | 字节序 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| `0..3` (4B) | `magic` | `UInt32` | Big-Endian | 协议魔数，ASCII `"MBCP"` (`0x4D424350`) |
| `4` (1B) | `version` | `UInt8` | - | 协议版本号，当前固定为 `1` (`0x01`) |
| `5` (1B) | `action` | `UInt8` | - | 动作类型，见动作类型表 |
| `6` (1B) | `modifiers` | `UInt8` | - | 8 位当前生效的修饰键位图掩码 |
| `7` (1B) | `flags` | `UInt8` | - | 扩展标志位（保留，默认 `0x00`） |
| `8..9` (2B) | `hidUsage` | `UInt16` | Big-Endian | USB HID Keyboard Page (0x07) 16 位 Usage 编码 |
| `10..11` (2B) | `param` | `UInt16` | Big-Endian | 动作参数（例如 Pulse 按住时长毫秒数，默认 20ms） |
| `12..15` (4B) | `sequence` | `UInt32` | Big-Endian | 单调递增序号（防重复包、统计丢包与延迟） |

---

## 3. 动作类型（Action）

| 值 | 标识名 | 描述 |
| :--- | :--- | :--- |
| `0x01` | `keyDown` | 按键按下事件 |
| `0x02` | `keyUp` | 按键抬起事件 |
| `0x03` | `pulse` | 单包脉冲事件（被控端收到后执行 KeyDown，等待 `param` 毫秒后自动执行 KeyUp） |
| `0x04` | `heartbeat`| 状态同步 / 心跳保活（包含当前修饰键掩码） |
| `0x05` | `resetAll` | 紧急复位事件（立即释放所有处于按下状态的按键与修饰键） |

---

## 4. 8 位修饰键掩码（Modifiers）

| 位 (Bit) | 十六进制值 | 对应按键 | 便捷语义 |
| :--- | :--- | :--- | :--- |
| `Bit 0` | `0x01` | Left Control | Ctrl / ⌃ |
| `Bit 1` | `0x02` | Left Shift | Shift / ⇧ |
| `Bit 2` | `0x04` | Left Option / Alt | Option / Alt / ⌥ |
| `Bit 3` | `0x08` | Left Command / Win | Command / Win / ⌘ / ⊞ |
| `Bit 4` | `0x10` | Right Control | Right Ctrl |
| `Bit 5` | `0x20` | Right Shift | Right Shift |
| `Bit 6` | `0x40` | Right Option / Alt | Right Option / Alt |
| `Bit 7` | `0x80` | Right Command / Win | Right Command / Win |

---

## 5. USB HID Usage 16 位统一按键标识

遵循 USB HID Usage Tables (Page 0x07: Keyboard/Keypad Page) 标准，典型值如下：

- **字母键**：`A` = `0x0004` ... `Z` = `0x001D`
- **数字键**：`1` = `0x001E` ... `0` = `0x0027`
- **特殊键**：
  - Return/Enter: `0x0028`
  - Escape: `0x0029`
  - Delete/Backspace: `0x002A`
  - Tab: `0x002B`
  - Space: `0x002C`
  - Minus (-/_): `0x002D`
  - Equal (=/+): `0x002E`
  - Left Bracket ([/{): `0x002F`
  - Right Bracket (]/}): `0x0030`
  - Backslash (\|): `0x0031`
  - Semicolon (;/:): `0x0033`
  - Quote ('/"): `0x0034`
  - Grave Accent (~/`): `0x0035`
  - Comma (,/ <): `0x0036`
  - Period (./>): `0x0037`
  - Slash (/?): `0x0038`
  - CapsLock: `0x0039`
- **功能键**：`F1` = `0x003A` ... `F12` = `0x0045`
- **导航键**：
  - Right Arrow: `0x004F`
  - Left Arrow: `0x0050`
  - Down Arrow: `0x0051`
  - Up Arrow: `0x0052`

---

## 6. 多语言解析示例

### Python 3 解析示例
```python
import struct

MAGIC = 0x4D424350 # "MBCP"
FORMAT = ">IBBBBHHI" # 16 bytes: uint32, uint8, uint8, uint8, uint8, uint16, uint16, uint32

def parse_packet(data: bytes):
    if len(data) != 16:
        return None
    magic, version, action, modifiers, flags, hid_usage, param, sequence = struct.unpack(FORMAT, data)
    if magic != MAGIC or version != 1:
        return None
    return {
        "action": action,
        "modifiers": modifiers,
        "flags": flags,
        "hid_usage": hid_usage,
        "param": param,
        "sequence": sequence,
    }
```

### C / C++ 结构体映射示例
```c
#pragma pack(push, 1)
typedef struct {
    uint32_t magic;      // 0x4D424350 (Big Endian)
    uint8_t  version;    // 1
    uint8_t  action;     // CompanionAction
    uint8_t  modifiers;  // Modifier bitmask
    uint8_t  flags;      // Flags (0)
    uint16_t hid_usage;  // Big Endian
    uint16_t param;      // Big Endian
    uint32_t sequence;   // Big Endian
} MBCPPacket;
#pragma pack(pop)
```
