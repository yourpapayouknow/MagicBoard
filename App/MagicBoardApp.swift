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
    case overview = "概览"
    case input = "中文输入"
    case style = "外观与布局"
    case feedback = "按键体验"
    case test = "输入测试"
    case about = "关于"

    var id: String { rawValue }

    // 返回边栏导航图标
    var icon: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .input: "character.bubble"
        case .style: "slider.horizontal.3"
        case .feedback: "hand.tap"
        case .test: "keyboard"
        case .about: "info.circle"
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
    @State private var columns: NavigationSplitViewVisibility = .all
    @State private var page: Page? = .overview
    @State private var settings = SharedConfig.ldcfg()
    @State private var status = HostStatus.load()

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            List(selection: $page) {
                Section {
                    ForEach(Page.allCases) { item in
                        Label {
                            Text(LocalizedStringKey(item.rawValue))
                        } icon: {
                            Image(systemName: item.icon)
                        }
                            .tag(item)
                    }
                }
            }
            .listStyle(.sidebar)
        } detail: {
            switch page ?? .overview {
            case .overview:
                OverviewView(status: status, chineseEnabled: settings.chineseEnabled, refresh: refresh)
            case .input:
                InputView(chineseEnabled: $settings.chineseEnabled, scheme: $settings.scheme)
            case .style:
                StyleView(layout: $settings.layout, appearance: $settings.appearance)
            case .feedback:
                FeedbackView(
                    keySound: $settings.keySound,
                    simulatedHaptics: $settings.simulatedHaptics,
                    sticky: $settings.stickyModifiers,
                    mode: $settings.modifierMode,
                    fullAccess: status.report?.hasFullAccess == true
                )
            case .test:
                TestInputView()
            case .about:
                AboutView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(settings.appearance.accent.swclr)
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

// 展示页面通用滚动容器
private struct PageShell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// 展示现代设置卡片
private struct SettingCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey(title))
                .font(.headline)
            content
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.2), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
    }
}

// 展示启用概览
private struct OverviewView: View {
    let status: HostStatus
    let chineseEnabled: Bool
    let refresh: () -> Void

    var body: some View {
        PageShell {
            SetupCard(status: status, chineseEnabled: chineseEnabled, refresh: refresh)
        }
    }
}

// 展示安装入口与状态
private struct SetupCard: View {
    let status: HostStatus
    let chineseEnabled: Bool
    let refresh: () -> Void

    private var added: Bool { status.keyboardAdded || status.reportFresh }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 16) {
                Text("初始化")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .frame(height: 44, alignment: .topLeading)
                Spacer()
                Text("点击前往设置 →")
                    .foregroundStyle(.secondary)
                    .frame(height: 44, alignment: .center)
                Button(action: openKeyboardSettings) {
                    Image(systemName: "arrow.up.forward.app")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("打开键盘设置")
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("刷新状态")
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatusTile("键盘", ready: added)
                StatusTile("完全访问", ready: status.report?.hasFullAccess == true)
                StatusTile("设置同步", ready: status.group.available)
                StatusTile("中文输入", ready: chineseEnabled && status.report?.engineReady == true)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.cyan.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .cyan.opacity(0.08), radius: 22, y: 10)
    }

    // 直接打开系统键盘列表
    private func openKeyboardSettings() {
        guard let keyboard = URL(string: "App-Prefs:root=General&path=Keyboard/KEYBOARDS") else { return }
        UIApplication.shared.open(keyboard)
    }
}

// 展示紧凑状态卡
private struct StatusTile: View {
    let title: String
    let ready: Bool

    // 创建状态卡
    init(_ title: String, ready: Bool) {
        self.title = title
        self.ready = ready
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 0)
            Image(systemName: ready ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ready ? .green : .red)
                .accessibilityLabel(Text(LocalizedStringKey(ready ? "已就绪" : "未就绪")))
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement(children: .combine)
    }
}

// 展示中文输入设置
private struct InputView: View {
    @Binding var chineseEnabled: Bool
    @Binding var scheme: ChineseScheme
    private let columns = [GridItem(.adaptive(minimum: 138), spacing: 10)]

    var body: some View {
        PageShell {
            SettingCard(title: "输入方案") {
                Toggle("启用中文输入", isOn: $chineseEnabled)

                Divider()

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ChineseScheme.allCases) { item in
                        Button {
                            scheme = item
                        } label: {
                            Text(LocalizedStringKey(item.title))
                                .font(.subheadline.weight(scheme == item ? .semibold : .regular))
                                .foregroundStyle(scheme == item ? Color.white : Color.primary)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(
                                    scheme == item ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(Text(LocalizedStringKey(scheme == item ? "已选择" : "")))
                    }

                    Button(action: {}) {
                        Text("五笔 · 未来")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                    .accessibilityHint("未来提供")
                }
                .disabled(!chineseEnabled)
                .opacity(chineseEnabled ? 1 : 0.45)
            }
        }
    }
}

// 展示外观与布局设置
private struct StyleView: View {
    @Binding var layout: LayoutConfig
    @Binding var appearance: AppearanceConfig

    var body: some View {
        PageShell {
            KeyboardPreview(layout: layout, appearance: appearance)

            SettingCard(title: "外观") {
                Picker("模式", selection: $appearance.mode) {
                    ForEach(AppearanceMode.allCases) { item in
                        Text(LocalizedStringKey(item.title)).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                ColorPicker("强调色", selection: color($appearance.accent), supportsOpacity: false)
                if appearance.mode == .custom {
                    Divider()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ColorPicker("键盘", selection: color($appearance.board), supportsOpacity: false)
                        ColorPicker("按键", selection: color($appearance.key), supportsOpacity: false)
                        ColorPicker("文字", selection: color($appearance.text), supportsOpacity: false)
                    }
                }
            }

            SettingCard(title: "布局") {
                ValueSlider(title: "高度", value: $layout.height, range: 340 ... 430, suffix: " pt")
                ValueSlider(title: "水平键距", value: $layout.horizontalGap, range: 3 ... 9, suffix: " pt")
                ValueSlider(title: "垂直键距", value: $layout.verticalGap, range: 4 ... 12, suffix: " pt")
                ValueSlider(title: "外边距", value: $layout.outerInset, range: 4 ... 16, suffix: " pt")
            }

            Button("恢复默认") {
                layout = .standard
                appearance = .standard
            }
            .buttonStyle(.bordered)
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

// 展示带数值的滑块
private struct ValueSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(LocalizedStringKey(title))
                Spacer()
                Text("\(value, specifier: "%.0f")\(suffix)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 1)
        }
    }
}

// 保存预览解析后的动态键盘颜色
private struct PreviewPalette {
    let board: Color
    let ordinary: Color
    let function: Color
    let candidate: Color
    let text: Color
    let secondaryText: Color
    let border: Color
    let shadow: Color
    let accent: Color

    // 按扩展端规则解析当前外观模式
    init(appearance: AppearanceConfig, systemScheme: ColorScheme) {
        let dark = switch appearance.mode {
        case .dark: true
        case .light: false
        case .system, .custom: systemScheme == .dark
        }
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        let custom = appearance.mode == .custom
        board = custom
            ? appearance.board.swclr
            : Color(white: dark ? 0.11 : 0.78).opacity(dark ? 0.88 : 0.72)
        ordinary = custom ? appearance.key.swclr : Color(white: dark ? 0.39 : 0.99)
        function = custom ? appearance.board.swclr : Color(white: dark ? 0.25 : 0.67)
        candidate = custom
            ? appearance.key.swclr.opacity(0.82)
            : Color(uiColor: UIColor.secondarySystemFill.resolvedColor(with: traits))
        text = custom
            ? appearance.text.swclr
            : Color(uiColor: UIColor.label.resolvedColor(with: traits))
        secondaryText = custom
            ? appearance.text.swclr.opacity(0.65)
            : Color(uiColor: UIColor.secondaryLabel.resolvedColor(with: traits))
        border = Color.white.opacity(dark ? 0.10 : 0.42)
        shadow = Color.black.opacity(dark ? 0.88 : 0.52)
        accent = appearance.accent.swclr
    }
}

// 展示紧凑的实际键盘风格预览
private struct KeyboardPreview: View {
    @Environment(\.colorScheme) private var systemScheme
    let layout: LayoutConfig
    let appearance: AppearanceConfig

    var body: some View {
        let palette = PreviewPalette(appearance: appearance, systemScheme: systemScheme)
        let outerInset = CGFloat(layout.outerInset)
        let rowGap = CGFloat(layout.verticalGap)

        VStack(spacing: rowGap) {
            PreviewCandidateBar(palette: palette)
            PreviewSampleRow(layout: layout, palette: palette)
        }
        .padding(outerInset)
        .background(palette.board, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.24), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
    }
}

// 展示预览候选栏
private struct PreviewCandidateBar: View {
    let palette: PreviewPalette

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: "nihao")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.secondaryText)
            Text(verbatim: "你好")
                .foregroundStyle(palette.accent)
            Text(verbatim: "你")
                .foregroundStyle(palette.text)
            Text(verbatim: "拟好")
                .foregroundStyle(palette.text)
            Spacer(minLength: 0)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(palette.candidate, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .clipped()
    }
}

// 展示预览示例键行
private struct PreviewSampleRow: View {
    let layout: LayoutConfig
    let palette: PreviewPalette

    var body: some View {
        let keyGap = CGFloat(layout.horizontalGap)

        GeometryReader { proxy in
            let unit = max(0, proxy.size.width - (keyGap * 4)) / 9.6

            HStack(spacing: keyGap) {
                PreviewKey("Esc", function: true, alignment: .bottomLeading, palette: palette)
                    .frame(width: unit * 1.2)
                PreviewKey("a", fontSize: 22, palette: palette)
                    .frame(width: unit)
                PreviewKey(symbol: "command", function: true, palette: palette)
                    .frame(width: unit)
                PreviewKey("space", palette: palette)
                    .frame(width: unit * 4)
                PreviewArrowKeys(gap: keyGap, palette: palette)
                    .frame(width: unit * 2.4)
            }
        }
        .frame(height: rowHeight)
    }

    private var rowHeight: CGFloat {
        let available = CGFloat(layout.height)
            - (CGFloat(layout.outerInset) * 2)
            - 44
            - (CGFloat(layout.verticalGap) * 6)
        return max(40, available / 6)
    }
}

// 展示预览方向键簇
private struct PreviewArrowKeys: View {
    let gap: CGFloat
    let palette: PreviewPalette

    var body: some View {
        HStack(spacing: max(2, gap / 2)) {
            PreviewKey(symbol: "arrowtriangle.left.fill", function: true, fontSize: 12, palette: palette)
            VStack(spacing: 3) {
                PreviewKey(symbol: "arrowtriangle.up.fill", function: true, fontSize: 12, palette: palette)
                PreviewKey(symbol: "arrowtriangle.down.fill", function: true, fontSize: 12, palette: palette)
            }
            PreviewKey(symbol: "arrowtriangle.right.fill", function: true, fontSize: 12, palette: palette)
        }
    }
}

// 展示预览中的单个键帽
private struct PreviewKey: View {
    let title: String
    let symbol: String?
    let function: Bool
    let alignment: Alignment
    let fontSize: CGFloat
    let palette: PreviewPalette

    // 创建紧凑预览键帽
    init(
        _ title: String = "",
        symbol: String? = nil,
        function: Bool = false,
        alignment: Alignment = .center,
        fontSize: CGFloat = 15,
        palette: PreviewPalette
    ) {
        self.title = title
        self.symbol = symbol
        self.function = function
        self.alignment = alignment
        self.fontSize = fontSize
        self.palette = palette
    }

    var body: some View {
        Group {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: fontSize, weight: .regular))
            } else {
                Text(verbatim: title)
                    .font(.system(size: fontSize, weight: .medium))
                    .minimumScaleFactor(0.6)
            }
        }
        .foregroundStyle(palette.text)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .padding(5)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(function ? palette.function : palette.ordinary)
                .shadow(color: palette.shadow, radius: 0.75, y: 1.75)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(palette.border, lineWidth: 0.5)
        }
    }
}
// 展示反馈与修饰键设置
private struct FeedbackView: View {
    @Binding var keySound: Bool
    @Binding var simulatedHaptics: Bool
    @Binding var sticky: Bool
    @Binding var mode: ModifierMode
    let fullAccess: Bool

    var body: some View {
        PageShell {
            SettingCard(title: "声音与触感") {
                Toggle("按键音", isOn: $keySound)
                Divider()
                Toggle("模拟触觉", isOn: $simulatedHaptics)
                if simulatedHaptics {
                    Text(LocalizedStringKey(fullAccess ? "仅内置扬声器；外接音频时自动停用" : "需要允许完全访问"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            SettingCard(title: "修饰键") {
                Toggle("Sticky Modifier", isOn: $sticky)
                Divider()
                Picker("操作模式", selection: $mode) {
                    ForEach(ModifierMode.allCases) { item in
                        Text(LocalizedStringKey(item.title)).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                Text("混合：长按临时 · 单击一次 · 双击锁定")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// 提供系统文本框用于验证输入法
private struct TestInputView: View {
    @State private var text = ""

    var body: some View {
        PageShell {
            SettingCard(title: "试一试") {
                Text("长按地球键，选择 MagicBoard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("在这里输入…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 17)
                    }
                    TextEditor(text: $text)
                        .font(.title3)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 320)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .opacity(text.isEmpty ? 0.98 : 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.5)
                }
            }
        }
    }
}

// 展示版本与开源致谢
private struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        PageShell {
            SettingCard(title: "版本信息") {
                LabeledContent("版本", value: version)
                Divider()
                LabeledContent("构建号", value: build)
                Divider()
                LabeledContent("作者", value: "iwmei")
            }

            SettingCard(title: "致谢") {
                Text("感谢 Rime 输入法引擎、LibrimeKit 与开源社区。")
                    .foregroundStyle(.secondary)
            }
        }
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
