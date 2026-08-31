// 显示输入法安装引导与共享主题状态
import MagicBoardShared
import SwiftUI

// 启动主应用
@main
struct MagicBoardApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

// 定义主应用页面
private enum Page: String, CaseIterable, Identifiable {
    case setup = "安装引导"
    case theme = "主题预览"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .setup: "keyboard"
        case .theme: "paintpalette"
        }
    }
}

// 展示自适应分栏
private struct MainView: View {
    @State private var page: Page? = .setup
    @State private var theme = SharedConfig.ldthm()
    @State private var groupState = SharedConfig.dgst()

    var body: some View {
        NavigationSplitView {
            List(Page.allCases, selection: $page) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("MagicBoard")
        } detail: {
            ScrollView {
                VStack(spacing: 20) {
                    switch page ?? .setup {
                    case .setup:
                        StatusCard(state: groupState)
                        StepsCard()
                        ThemeCard(theme: theme, action: syncthm)
                    case .theme:
                        ThemeCard(theme: theme, action: syncthm)
                        StatusCard(state: groupState)
                    }
                }
                .padding(24)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle((page ?? .setup).rawValue)
        }
    }

    // 同步默认主题
    private func syncthm() {
        theme = .cyanOrange
        SharedConfig.svthm(theme)
        groupState = SharedConfig.dgst()
    }
}

// 显示共享容器状态
private struct StatusCard: View {
    let state: GroupState

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("安装链路状态", systemImage: state.available ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(state.available ? .cyan : .orange)
                Text(state.message)
                    .font(.body)
                Text("iPadOS 不提供查询第三方键盘是否已启用的公开 API，请按下方路径在设置中确认。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// 显示系统设置步骤
private struct StepsCard: View {
    private let steps = [
        "使用 TrollStore 安装 MagicBoard.tipa 并打开主 App。",
        "前往 设置 > 通用 > 键盘 > 键盘 > 添加新键盘。",
        "选择 MagicBoard，然后打开“允许完全访问”。",
        "在任意文本框长按地球键并切换到 MagicBoard。",
    ]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("添加 MagicBoard", systemImage: "list.number")
                    .font(.title2.bold())
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 30, height: 30)
                            .background(.cyan.opacity(0.18), in: Circle())
                        Text(step)
                            .font(.body)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
}

// 显示青橙主题预览
private struct ThemeCard: View {
    let theme: BoardTheme
    let action: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("共享主题", systemImage: "paintpalette.fill")
                    .font(.title2.bold())
                HStack(spacing: 12) {
                    ThemeSwatch(name: "主色", color: theme.primary.swclr)
                    ThemeSwatch(name: "强调", color: theme.accent.swclr)
                }
                Button("同步默认青橙主题", action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(theme.primary.swclr)
                Text("主题使用语义颜色存入 App Group；任务 01 提供预览与共享模型，不扩展为完整编辑器。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// 显示主题色块
private struct ThemeSwatch: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.gradient)
                .frame(height: 82)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "keyboard.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(12)
                }
            Text(name)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

// 复用玻璃卡片样式
private struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 14, y: 7)
    }
}

// 转换共享主题颜色
private extension ThemeColor {
    var swclr: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
