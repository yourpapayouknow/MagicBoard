# MagicBoard 伴侣服务部署与 Tailscale 异地组网操作指南

---

## 1. 概述与核心技术原理

### 1.1 远程桌面打字与按键穿透的行业痛点
当使用 iPad 搭配远程桌面软件（如**网易UU远程**、**向日葵**、**ToDesk**、**TeamViewer**、**RDP** 等）远程操控 macOS 或 Windows 电脑时，用户普遍面临严重的按键劫持与缺失问题：
1. **系统全局快捷键被 iPadOS 拦截**：例如按下 `Command+Space` 会弹出 iPad 聚焦搜索而非被控端 Spotlight，按下 `Command+Tab` 切换的是 iPad 后台应用而非电脑窗口；
2. **特殊控制键缺失**：iPad 虚拟键盘或常规蓝牙键盘缺少物理 `Esc`、`F1 ~ F12`、Windows `Win` 键、右键菜单键等；
3. **修饰键状态不同步与悬空卡键**：由于远程协议自身的网络抖动，`Ctrl` / `Alt` / `Shift` / `Win` / `Command` 按下后若丢包，极易导致对端按键一直处于按住状态，造成输入紊乱甚至无法退出全屏。

### 1.2 MagicBoard 伴侣模式解决之道（双通道旁路直连）
MagicBoard 创造性地采用了**双通道旁路直连架构**：
```
┌────────────────────────────────────────────────────────┐
│                        iPad                            │
│  ┌────────────────────────┐  ┌──────────────────────┐  │
│  │ 网易UU远程 / 远程桌面App │  │ MagicBoard 键盘扩展   │  │
│  │ (负责接收高帧率画面流)   │  │ (纯本地 UI 渲染)     │  │
│  └───────────┬────────────┘  └──────────┬───────────┘  │
└──────────────┼──────────────────────────┼──────────────┘
               │ 画面流传输               │ MBCP 旁路直连 (UDP 16B)
               ▼                          ▼
┌────────────────────────────────────────────────────────┐
│                   目标电脑 (macOS / Win)                 │
│  ┌────────────────────────┐  ┌──────────────────────┐  │
│  │ 远程桌面服务端 (UU/ToDesk)│  │ MagicBoard Companion │  │
│  └────────────────────────┘  │ (CoreGraphics/Send)  │  │
│                              └──────────┬───────────┘  │
│                                         │ 原生 HID 注入 │
│                                         ▼              │
│                              [ 操作系统底层输入事件队列 ] │
└────────────────────────────────────────────────────────┘
```
- **画面走远程桌面**：利用网易UU远程等专长做低延迟、高帧率桌面串流；
- **按键走 MBCP 专用通道**：iPad 键盘按下时，直接通过局域网或 Tailscale 发送 16 字节超紧凑二进制 UDP 数据包至电脑后台的 `MagicBoard Companion`；
- **系统底层原生注入**：伴侣端利用 macOS `CoreGraphics` 或 Windows `SendInput` API，将标准 USB HID Usage 转换为原生扫描码注入操作系统底层队列；
- **全物理特性支持**：`Command+Space`、`Alt+Tab`、`Win+D`、`F1~F12`、`Esc`、方向键全部毫秒级原生穿透，彻底绕过 iPadOS 劫持与远程桌面的协议限制。

---

## 2. macOS 被控端伴侣部署指南

macOS 伴侣服务提供**原生编译二进制（推荐）**与**纯 Python 3 备用脚本（零依赖）**两种形态。

### 2.1 方式 A：Swift 原生单文件编译（推荐，性能最高）
1. 打开 macOS 终端（Terminal），进入项目目录：
   ```zsh
   cd Companion/macOS
   ```
2. 编译生成原生可执行文件：
   ```zsh
   ./build-mac.zsh
   ```
   *编译产物为 `cpmac`（仅约 103KB，零外部依赖，极低内存消耗）。*
3. 运行服务（默认监听 UDP `52088` 端口）：
   ```zsh
   ./cpmac
   ```
   如需自定义端口，可传入参数：
   ```zsh
   ./cpmac -p 52188
   ```

### 2.2 方式 B：Python 3 零依赖备用脚本
如果不想进行编译，可直接使用系统内置的 Python 3 运行（通过 `ctypes` 直接调用系统底层 CoreGraphics 动态库，无需 `pip install` 任何第三方包）：
```zsh
python3 Companion/macOS/magicboard_companion.py
```

### 2.3 辅助功能权限配置（必须）
macOS 注入按键需要系统辅助功能（Accessibility）授权：
1. 首次启动时，若终端未获得授权，伴侣将提示并自动弹窗；
2. 前往 **「系统设置」 $\rightarrow$ 「隐私与安全性」 $\rightarrow$ 「辅助功能」**；
3. 将您运行伴侣服务的终端应用（如 `Terminal`、`iTerm2`）勾选开启允许；如果将二进制作为独立应用运行，请添加并勾选 `cpmac`。

### 2.4 macOS 开机自动后台运行（LaunchAgent 配置）
若希望电脑开机/登录后自动在后台无感知运行伴侣服务：
1. 创建服务描述文件 `~/Library/LaunchAgents/com.iwmei.magicboard.companion.plist`：
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.iwmei.magicboard.companion</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/local/bin/cpmac</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <true/>
       <key>StandardOutPath</key>
       <string>/tmp/magicboard-companion.log</string>
       <key>StandardErrorPath</key>
       <string>/tmp/magicboard-companion.err</string>
   </dict>
   </plist>
   ```
2. 将编译好的二进制复制至系统路径并加载 LaunchAgent：
   ```zsh
   sudo cp cpmac /usr/local/bin/
   launchctl load -w ~/Library/LaunchAgents/com.iwmei.magicboard.companion.plist
   ```

---

## 3. Windows 被控端伴侣部署指南

Windows 伴侣服务提供 **C 语言绿色免安装原生版（推荐）** 与 **Python 3 备用脚本**。

### 3.1 方式 A：C 语言绿色版免安装单文件（推荐）
1. 文件位置：[`Companion/Windows/cpwin.exe`](file:///Users/mac/codexproj/magicboard/Companion/Windows/cpwin.exe)（编译自 `cpwin.c` 与 `head.h`，纯 Win32 API 编写）；
2. **以管理员身份运行**：
   - 右键点击 `cpwin.exe`，选择「**以管理员身份运行**」；
   - *重要说明*：Windows 存在 UIPI（用户界面特权隔离）机制，非管理员权限进程无法向高权限窗口（如任务管理器、注册表编辑器、以管理员运行的编辑器等）注入键盘事件。以管理员身份运行可确保按键 100% 穿透至任意前台窗口。

### 3.2 方式 B：Python 3 零依赖备用脚本
通过 Windows 原生 `ctypes` 调用 `user32.dll` 中的 `SendInput`，无需额外安装任何第三方依赖：
```powershell
pwsh -Command "python Companion\Windows\magicboard_companion.py"
```

### 3.3 Windows 防火墙 UDP 端口一键放行（必须）
为防止 Windows Defender 防火墙拦截来自局域网或虚拟网的 UDP 52088 报文，以管理员身份在 PowerShell 中执行以下单行命令：
```powershell
New-NetFirewallRule -DisplayName "MagicBoard Companion" -Direction Inbound -LocalPort 52088 -Protocol UDP -Action Allow
```

### 3.4 Windows 开机自启计划任务（突破 UAC 静默启动）
通过 Windows 任务计划程序，可以在登录时自动以最高权限在后台启动伴侣服务，且不会弹出 UAC 确认框：
以管理员身份打开 PowerShell 执行：
```powershell
$Action = New-ScheduledTaskAction -Execute "C:\Path\To\cpwin.exe"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
Register-ScheduledTask -TaskName "MagicBoardCompanion" -Action $Action -Trigger $Trigger -Principal $Principal
```

---

## 4. Tailscale 异地远控组网实战指南

当 iPad 与被控电脑不在同一局域网（例如在外出差、咖啡馆、移动热点等异地场景）时，推荐使用 **Tailscale** 建立点对点 Mesh 虚拟局域网。

### 4.1 为什么推荐 Tailscale？
1. **零公网 IP 与零端口映射**：底层基于 WireGuard 协议，自动穿透各类 NAT / 防火墙，建立高强度加密点对点直连（P2P Direct Connection）；
2. **超低额外延迟**：两端直连成功后，数据包直接在公网路由器间以最短路径传输，无中心服务器转发损耗；
3. **固定内网 IP**：每台设备接入后获得专属的固定 100.x.y.z IP，不受物理 Wi-Fi 变更影响；
4. **完全免费**：个人账号支持最多 3 台设备免费使用，满足 iPad + 笔记本 + 台式机需求。

### 4.2 配置步骤

#### 第一步：电脑端（macOS / Windows）配置
1. 访问 [tailscale.com](https://tailscale.com) 下载并安装对应系统客户端；
2. 登录个人账号（支持 Apple、Google、Microsoft 或 GitHub 账号）；
3. 登录后在 Tailscale 状态栏/托盘图标中查看分配的 IPv4 地址（例如：`100.88.99.2`）；
4. 确保伴侣服务（`cpmac` 或 `cpwin.exe`）已正常启动。

#### 第二步：iPad 端配置
1. 在 iPad 的 App Store 搜索并安装 **Tailscale** 应用；
2. 使用与电脑端相同的账号登录；
3. 授权安装 VPN 配置文件并开启连接；
4. 在设备列表中应能看到已在线的电脑设备及其 Tailscale IP（例如：`100.88.99.2`）。

#### 第三步：MagicBoard App 联动设置
1. 打开 iPad 上的 **MagicBoard** 主 App；
2. 在左侧导航栏点击「**远程伴侣**」；
3. 开启「**启用伴侣模式**」开关；
4. 目标系统预设选择：根据电脑实际系统选择 `macOS` 或 `Windows`；
5. 在「**被控端 IP / 域名**」中填入电脑的 Tailscale IP（例如 `100.88.99.2`）；
6. 端口保持默认 `52088`；
7. 点击下方「**发Ping测试**」按钮：
   - 界面若显示绿色 `Ping 探活成功 · 耗时 X.XX ms`，说明 Tailscale 网络隧道与电脑端伴侣监听完全打通！

---

## 5. 网易UU远程 / 远控软件实操穿透指南

### 5.1 推荐操作工作流
1. **开启连接**：在 iPad 上打开网易UU远程（或 ToDesk / 向日葵），连接至目标电脑，将远控窗口切换至**全屏模式**；
2. **调出键盘**：轻点输入区域或使用底部键盘呼出图标，切换至 **MagicBoard** 键盘；
3. **选择工作模式**（可在主 App 中随时调整）：
   - **编程与远程运维推荐「全键盘接管 (.fullKeyboard)」**：所有字母、数字、符号、控制键全部实时透传至电脑，本地不消耗文本，如同给电脑插了一把直连物理外接键盘；
   - **文档长文写作推荐「仅功能键分流 (.onlyFunctions)」**：字母输入使用 iPad 上的 MagicBoard Rime 中文词库选词，只有 `F1~F12`、`Esc`、`Tab`、方向键与修饰键发给电脑，兼顾打字流畅度与控制按键。

### 5.2 常用穿透快捷键操作对照表

| 操作意图 | macOS 场景按键 | Windows 场景按键 | 穿透效果与传统远程痛点对比 |
| :--- | :--- | :--- | :--- |
| **退出编辑 / 取消选择** | `Esc` | `Esc` | 彻底解决 iPad 软键盘无 Esc 的问题，Vim / 终端秒退插入模式 |
| **代码缩进 / 焦点跳转** | `Tab` | `Tab` | 传统远控 Tab 常被 iPadOS 焦点抢占，伴侣模式 100% 直达对端 |
| **全选内容** | `Command + A` | `Ctrl + A` | 原生穿透，不触发 iPad 系统的编辑菜单 |
| **窗口切换** | `Command + Tab` | `Alt + Tab` | 完美穿透！切换电脑窗口，绝不呼出 iPad 多任务视图 |
| **全局启动器 / 搜索** | `Command + Space` | `Win` 键 | 弹出电脑 Spotlight / Raycast / 开始菜单，绝不弹出 iPad 搜索框 |
| **刷新页面 / 开发者调试** | `F5` / `F12` | `F5` / `F12` | 浏览器网页即时刷新，Chrome DevTools 秒开 |
| **显示桌面** | `F11` (显示桌面) | `Win + D` | Windows 瞬间最小化全部窗口显示桌面 |
| **打开文件管理器** | `Command + Option + Space` | `Win + E` | 秒开 macOS Finder 或 Windows 资源管理器 |
| **终端强行中断** | `Control + C` | `Ctrl + C` | 毫秒级中止 Linux / Windows 正在运行的脚本或编译进程 |

---

## 6. 防卡键与异常断网自愈机制说明

UDP 协议属于无连接传输，在网络极度不稳定或无线抖动时，按键可能发生丢包。MagicBoard 设计了三重保险机制确保永不卡键：

1. **Pulse 单包脉冲机制**：
   对于单次击键（如 `Esc`、`Tab`、`F1~F12`、方向键），iPad 端发送 `Pulse` 指令，携带 `param: 20ms` 持续时间。伴侣端收到单包后自动在本地完成「按下 $\rightarrow$ 维持 20ms $\rightarrow$ 抬起」，无需两次网络交互，即使后续网络瞬间中断，按键也不会处于长按卡死状态。
2. **1.5 秒断网看门狗（Hardware-like Watchdog）**：
   对于长按或组合键（如按住 `Shift` 拖选），如果 iPad 端网络突然断开或键盘突然收起，伴侣端看门狗后台线程在检测到距离最后一次有效通信超过 1.5 秒后，将自动调用 `resetAll()`，向操作系统注入所有按键与修饰键的抬起事件，彻底消除按键悬空（Sticky Key Bug）。
3. **手动一键复位（Emergency Reset）**：
   在任何极端异常情况下，只需长按空格键复位或在键盘收起时，iPad 端均会广播发送 `resetAll` 报文，伴侣端收到后将在 1 微秒内强行重置所有按键状态。

---

## 7. 常见问题排查（FAQ）

- **Q1: 点击「发Ping测试」提示连接超时或拒绝？**
  - **A**: 检查目标电脑上伴侣服务是否已启动并处于监听状态；检查 Windows 防火墙是否已按 3.3 节放行 UDP 52088 端口；检查 Tailscale 两端是否均处于 Connected 状态。
- **Q2: 提示「本地网络权限被系统拒绝」？**
  - **A**: iOS 14+ 要求授权局域网访问。请点击界面上的「打开应用设置」按钮，在系统设置中将 MagicBoard 的「本地网络」权限开启。
- **Q3: 网易UU远程中无法穿透 Command/Win 键？**
  - **A**: 请检查 MagicBoard 主 App 中的「远程伴侣」总开关是否为开启状态，并确认「目标系统预设」选择与电脑实际操作系统匹配（macOS 映射 Command，Windows 映射 Win）。
- **Q4: Windows 上个别软件（如任务管理器）按键无反应？**
  - **A**: 这是 Windows UIPI 特权隔离保护所致。请务必右键 `cpwin.exe` 并选择「以管理员身份运行」。
