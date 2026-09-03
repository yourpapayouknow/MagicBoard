// 展示并同步 MagicBoard 输入法设置
import MagicBoardShared
import SwiftUI
import UIKit

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
    case settings = "输入法设置"
    case test = "输入测试"

    var id: String { rawValue }

    // 返回页面图标
    var icon: String {
        switch self {
        case .settings: "keyboard"
        case .test: "text.cursor"
        }
    }
}

// 保存主应用展示的键盘状态
private struct HostStatus {
    let group: GroupState
    let report: KeyboardReport?
    let keyboardAdded: Bool

    // 判断键盘扩展是否刚刚运行过
    var reportFresh: Bool {
        guard let report else { return false }
        return Date().timeIntervalSince(report.lastSeen) < 120
    }

    // 读取系统与共享容器状态
    static func load() -> HostStatus {
        let keyboards = UserDefaults.standard.stringArray(forKey: "AppleKeyboards") ?? []
        let added = keyboards.contains { $0.contains("com.iwmei.magicboard.keyboard") }
        return HostStatus(group: SharedConfig.dgst(), report: SharedConfig.ldrpt(), keyboardAdded: added)
    }
}

// 展示自适应设置分栏
private struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var page: Page? = .settings
    @State private var settings = SharedConfig.ldcfg()
    @State private var status = HostStatus.load()

    var body: some View {
        NavigationSplitView {
            List(Page.allCases, selection: $page) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("MagicBoard")
        } detail: {
            switch page ?? .settings {
            case .settings:
                SettingsView(settings: $settings, status: status, refresh: refresh)
            case .test:
                TestInputView()
            }
        }
        .preferredColorScheme(settings.appearance.mode.scheme)
        .onChange(of: settings) { value in
            SharedConfig.svcfg(value)
        }
        .onChange(of: scenePhase) { value in
            if value == .active { refresh() }
        }
    }

    // 刷新共享设置与键盘状态
    private func refresh() {
        settings = SharedConfig.ldcfg()
        status = HostStatus.load()
    }
}

// 展示完整输入法设置
private struct SettingsView: View {
    @Binding var settings: BoardSettings
    let status: HostStatus
    let refresh: () -> Void

    var body: some View {
        Form {
            SetupSection(status: status, refresh: refresh)
            ChineseSection(scheme: $settings.scheme)
            LayoutSection(layout: $settings.layout)
            AppearanceSection(appearance: $settings.appearance)
            FeedbackSection(
                keySound: $settings.keySound,
                simulatedHaptics: $settings.simulatedHaptics,
                fullAccess: status.report?.hasFullAccess
            )
            ModifierSection(
                sticky: $settings.stickyModifiers,
                mode: $settings.modifierMode
            )
            Section {
                NavigationLink("打开输入测试", value: Page.test)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("输入法设置")
    }
}

// 展示安装入口与状态
private struct SetupSection: View {
    let status: HostStatus
    let refresh: () -> Void

    var body: some View {
        Section("启用 MagicBoard") {
            StatusRow("已添加到键盘", ready: status.keyboardAdded || status.reportFresh)
            StatusRow("App Group 设置同步", ready: status.group.available)
            StatusRow("允许完全访问", ready: status.report?.hasFullAccess == true)
            StatusRow("中文输入引擎", ready: status.report?.engineReady == true)

            Button {
                openKeyboardSettings()
            } label: {
                Label("前往“添加新键盘”", systemImage: "gear")
            }
            .buttonStyle(.borderedProminent)

            Button("刷新状态", action: refresh)

            Text("在系统设置中添加 MagicBoard 并允许完全访问。返回此页后会自动刷新；状态以键盘最近一次启动报告为准。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // 打开 TrollStore 环境中的键盘设置并提供公开回退
    private func openKeyboardSettings() {
        let fallback = URL(string: UIApplication.openSettingsURLString)!
        guard let keyboard = URL(string: "App-Prefs:root=General&path=Keyboard/KEYBOARDS") else {
            UIApplication.shared.open(fallback)
            return
        }
        UIApplication.shared.open(keyboard, options: [:]) { opened in
            if !opened { UIApplication.shared.open(fallback) }
        }
    }
}

// 展示单项状态
private struct StatusRow: View {
    let title: String
    let ready: Bool

    // 创建状态行
    init(_ title: String, ready: Bool) {
        self.title = title
        self.ready = ready
    }

    var body: some View {
        Label(title, systemImage: ready ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(ready ? .green : .secondary)
    }
}

// 展示中文输入方案
private struct ChineseSection: View {
    @Binding var scheme: ChineseScheme

    var body: some View {
        Section {
            Picker("输入方案", selection: $scheme) {
                ForEach(ChineseScheme.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            LabeledContent("五笔", value: "未来提供")
                .foregroundStyle(.secondary)
            LabeledContent("系统词典", value: "自动补充联系人与文本替换")
            LabeledContent("系统习惯迁移", value: "等待实体机格式验证")
                .foregroundStyle(.secondary)
        } header: {
            Text("中文输入")
        } footer: {
            Text("双拼包含微软、自然码、智能 ABC、小鹤、拼音加加和四通；微软双拼排在首位。")
        }
    }
}

// 展示精确布局控制
private struct LayoutSection: View {
    @Binding var layout: LayoutConfig

    var body: some View {
        Section("键盘布局") {
            ValueSlider(title: "键盘高度", value: $layout.height, range: 340 ... 430, suffix: " pt")
            ValueSlider(title: "水平键距", value: $layout.horizontalGap, range: 3 ... 9, suffix: " pt")
            ValueSlider(title: "垂直键距", value: $layout.verticalGap, range: 4 ... 12, suffix: " pt")
            ValueSlider(title: "外边距", value: $layout.outerInset, range: 4 ... 16, suffix: " pt")
            Button("恢复标准布局") { layout = .standard }
        }
    }
}

// 展示带数值的滑块
private struct ValueSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value, specifier: "%.0f")\(suffix)")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 1)
        }
    }
}

// 展示外观与预览
private struct AppearanceSection: View {
    @Binding var appearance: AppearanceConfig

    var body: some View {
        Section("外观") {
            Picker("模式", selection: $appearance.mode) {
                ForEach(AppearanceMode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            ColorPicker("强调色", selection: color($appearance.accent), supportsOpacity: false)
            if appearance.mode == .custom {
                ColorPicker("键盘底色", selection: color($appearance.board), supportsOpacity: false)
                ColorPicker("按键颜色", selection: color($appearance.key), supportsOpacity: false)
                ColorPicker("文字颜色", selection: color($appearance.text), supportsOpacity: false)
            }
            KeyboardPreview(appearance: appearance)
            Button("恢复默认外观") { appearance = .standard }
        }
    }

    // 转换共享颜色绑定
    private func color(_ source: Binding<ThemeColor>) -> Binding<Color> {
        Binding(
            get: { source.wrappedValue.swclr },
            set: { source.wrappedValue = ThemeColor($0) }
        )
    }
}

// 展示按键外观预览
private struct KeyboardPreview: View {
    let appearance: AppearanceConfig

    var body: some View {
        HStack(spacing: 7) {
            ForEach(["中", "A", "⌘", "空格"], id: \.self) { key in
                Text(key)
                    .font(.headline)
                    .foregroundStyle(appearance.text.swclr)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(appearance.key.swclr, in: RoundedRectangle(cornerRadius: 9))
            }
        }
        .padding(8)
        .background(appearance.board.swclr, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 1)
        }
    }
}

// 展示声音与模拟触觉开关
private struct FeedbackSection: View {
    @Binding var keySound: Bool
    @Binding var simulatedHaptics: Bool
    let fullAccess: Bool?

    var body: some View {
        Section("按键反馈") {
            Toggle("按键音", isOn: $keySound)
            Toggle("扬声器模拟触觉", isOn: $simulatedHaptics)
            if simulatedHaptics {
                Text(fullAccess == true
                     ? "仅使用内置扬声器播放极短低频脉冲；耳机、蓝牙或外部音频输出接入时自动停用。"
                     : "该功能需要允许完全访问；外部音频输出接入时会自动停用。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// 展示修饰键行为设置
private struct ModifierSection: View {
    @Binding var sticky: Bool
    @Binding var mode: ModifierMode

    var body: some View {
        Section {
            Toggle("Sticky Modifier", isOn: $sticky)
            Picker("操作模式", selection: $mode) {
                ForEach(ModifierMode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Modifier 修饰键")
        } footer: {
            Text("混合模式：按住为临时生效；开启 Sticky 后，单击作用于下一键，双击持续锁定。")
        }
    }
}

// 提供系统文本框用于验证输入法
private struct TestInputView: View {
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("切换到 MagicBoard，测试中文候选、双拼、修饰键和布局变化。")
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.title3)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(uiColor: .separator), lineWidth: 1)
                }
        }
        .padding(24)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("输入测试")
    }
}

// 转换共享主题颜色
private extension ThemeColor {
    var swclr: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    // 从 SwiftUI 颜色创建共享颜色
    init(_ color: Color) {
        let resolved = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// 转换外观模式到系统色彩方案
private extension AppearanceMode {
    var scheme: ColorScheme? {
        switch self {
        case .system, .custom: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
