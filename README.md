<div align="center">

![MagicBoard 项目徽章](assets/readme-badge.png)

# MagicBoard

面向 TrollStore iPad 的 Mac 风格全尺寸键盘，兼顾普通输入、离线中文与实体键盘级快捷键。

[English](README_EN.md) · [下载安装包](../../releases/latest)

</div>

![MagicBoard 在 iPad Pro 模拟器中的输入测试](docs/magicboard-simulator.png)

MagicBoard 是一个 iPadOS Keyboard Extension。它提供六行 Mac 风格布局、离线 Rime 中文输入，以及通过 HID 派发的 Esc、Tab、F1–F12、Ctrl、Option、Command 和方向键。配套主 App 用于启用检查、中文方案、外观布局、按键反馈和 Modifier 行为设置。

> [!IMPORTANT]
> MagicBoard 使用 TrollStore 与私有 HID entitlement，不适用于 App Store、普通侧载签名或未安装 TrollStore 的设备。当前最低系统版本为 iPadOS 16.0。

## 快速开始

把本仓库链接交给你的代码代理，然后直接说：

```text
帮我安装这个仓库，并把最新 MagicBoard.tipa 安装到已连接的 TrollStore iPad。
```

## 传统开始

1. 从 [Releases](../../releases/latest) 下载 `MagicBoard.tipa`。
2. 在 iPad 上使用 TrollStore 安装该文件。
3. 打开 MagicBoard，按引导进入“设置 > 通用 > 键盘 > 键盘”。
4. 添加 MagicBoard，并允许完全访问。
5. 打开任意普通文本框，使用地球键切换到 MagicBoard。

> [!NOTE]
> 密码框和主动禁止第三方输入法的 App 会由 iPadOS 自动回退到系统键盘，这是预期的安全行为。

## 功能

- 六行 Mac 风格布局，支持横竖屏、明暗外观和自定义尺寸/间距/颜色。
- 普通文字、Shift/Caps Lock、Delete 连删、下滑副字符和触控板式光标移动。
- Esc、Tab、F1–F12、Ctrl、Option、Command 与四方向键 HID 行为。
- Modifier 按住、切换与混合模式，并在键盘离场、宿主后台或扩展重启时统一释放。
- 离线 Rime 全拼与六种双拼方案，候选栏和系统词典补充候选。
- 可配置按键音、内置扬声器模拟触觉、强调色和键盘外观。
- 可选远程伴侣模式，把功能键、修饰键或完整键盘输入转发到 macOS/Windows 被控端。

## 远程伴侣

远程桌面软件无法传递 iPad 第三方键盘产生的全部 HID 按键时，可以在被控电脑上运行 MagicBoard 伴侣。键盘通过局域网 UDP 把标准 HID Usage 发送给伴侣，再由 macOS 原生事件接口或 Windows `SendInput` 注入被控系统。

从最新 [GitHub Release](../../releases/latest) 下载对应平台的单文件程序：

- macOS（Apple Silicon）：[`cpmac`](https://github.com/yourpapayouknow/MagicBoard/releases/latest/download/cpmac)
- Windows 11 x64：[`cpwin.exe`](https://github.com/yourpapayouknow/MagicBoard/releases/latest/download/cpwin.exe)

macOS 首次运行时，在“系统设置 > 隐私与安全性 > 辅助功能”中允许当前终端或 `cpmac` 控制电脑：

```zsh
chmod +x ./cpmac
./cpmac --port 52088
```

Windows 推荐在 PowerShell 7 中启动；若当前窗口不是管理员权限，`--elevate` 会请求 UAC 提权：

```powershell
.\cpwin.exe --elevate --port 52088
```

然后在 iPad 的 MagicBoard 主 App 中打开“远程伴侣”，选择目标系统，填写被控端局域网地址、`.local` 域名或 Tailscale IP，保持相同端口并点击 Ping。连接成功后，键盘候选栏右侧的路由胶囊可在“本机 → 远端键 → 远端全”之间切换；每个新键盘会话始终从“本机”开始。

> [!WARNING]
> MBCP v1 使用无认证、无加密的 UDP 报文。只应在可信局域网或 Tailscale 私有网络中使用，不要把 52088 端口直接暴露到公网。若 Windows Ping 不通，请仅为当前可信网络放行 UDP 52088。

## 从源码构建

需要 macOS、Xcode 16、XcodeGen、`ldid`、Swift 6 工具链，以及系统自带的 `zip`、`unzip` 和 `plutil`。依赖必须可从网络解析。

```zsh
git clone <repository-url>
cd magicboard
./scripts/build-tipa.zsh
```

脚本会生成 Xcode 项目、执行 generic iOS Release 构建、分别为主 App 与键盘扩展应用 entitlement、校验 Bundle ID/版本/完全访问/HID 权限与 ZIP 结构，最后输出：

```text
build/MagicBoard.tipa
```

## 验证

```zsh
swift test --package-path Packages/MagicBoardShared
npx @google/design.md lint DESIGN.md
./scripts/build-tipa.zsh
```

最终发布前仍应在目标 TrollStore iPad 上复测第三方 App、终端/代码编辑器、系统限制输入框和实体触控组合；CoreSimulator 不能等价证明真实设备的私有 HID 与 jetsam 行为。

## 项目结构

| 路径 | 说明 |
| --- | --- |
| `App/` | SwiftUI 设置主 App |
| `Keyboard/` | UIKit Keyboard Extension、HID 桥、Rime 与资源 |
| `Packages/MagicBoardShared/` | 主 App/扩展共享配置、输入状态与测试 |
| `Companion/` | macOS 与 Windows 远程伴侣源码、构建和验收脚本 |
| `project.yml` | XcodeGen 项目、版本、依赖与 entitlement 定义 |
| `scripts/build-tipa.zsh` | 一键 Release 构建与 TrollStore `.tipa` 打包 |
| `DESIGN.md` | 界面设计系统与组件约束 |

## 技术说明

- 主 App：SwiftUI
- 键盘扩展：UIKit + Objective-C HID bridge
- 中文引擎：LibrimeKit / Rime，本地资源固定随扩展打包
- 配置同步：App Group `group.com.iwmei.magicboard`
- 远程协议：MBCP v1，UDP 52088，标准 USB HID Usage
- 发布产物：arm64、iPad-only、TrollStore `.tipa`
