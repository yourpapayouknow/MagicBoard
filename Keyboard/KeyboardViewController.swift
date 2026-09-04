// 显示基础文字输入键盘
import MagicBoardShared
import UIKit

// 标识按键行为
private enum KeyKind: Int {
    case text
    case shift
    case language
    case delete
    case tab
    case enter
    case space
    case next
    case dismiss
    case escape
    case f1
    case f2
    case f3
    case f4
    case f5
    case f6
    case f7
    case f8
    case f9
    case f10
    case f11
    case f12
    case leftArrow
    case rightArrow
    case upArrow
    case downArrow
    case control
    case leftOption
    case leftCommand
    case rightCommand
    case rightOption
    case placeholder

    // 返回特殊键对应的 HID usage
    var hidKey: MBHIDKey? {
        switch self {
        case .tab: .tab
        case .escape: .escape
        case .f1: .F1
        case .f2: .F2
        case .f3: .F3
        case .f4: .F4
        case .f5: .F5
        case .f6: .F6
        case .f7: .F7
        case .f8: .F8
        case .f9: .F9
        case .f10: .F10
        case .f11: .F11
        case .f12: .F12
        case .leftArrow: .leftArrow
        case .rightArrow: .rightArrow
        case .upArrow: .upArrow
        case .downArrow: .downArrow
        case .control: .control
        case .leftOption: .leftOption
        case .leftCommand: .leftCommand
        case .rightCommand: .rightCommand
        case .rightOption: .rightOption
        default: nil
        }
    }

    // 返回 Shift 图标层对应的系统 HID usage
    var systemKey: MBHIDSystemKey? {
        switch self {
        case .f1: .brightnessDown
        case .f2: .brightnessUp
        case .f3: .showWindows
        case .f4: .search
        case .f5: .voiceCommand
        case .f6: .doNotDisturb
        case .f7: .previousTrack
        case .f8: .playPause
        case .f9: .nextTrack
        case .f10: .mute
        case .f11: .volumeDown
        case .f12: .volumeUp
        default: nil
        }
    }

    // 返回物理修饰键对应的共享状态键
    var modifierKey: ModifierKey? {
        switch self {
        case .control: .control
        case .leftOption: .leftOption
        case .leftCommand: .leftCommand
        case .rightCommand: .rightCommand
        case .rightOption: .rightOption
        default: nil
        }
    }

    // 判断是否为可连续触发的方向键
    var isArrow: Bool {
        switch self {
        case .leftArrow, .rightArrow, .upArrow, .downArrow: true
        default: false
        }
    }
}

// 标识键帽内容对齐
private enum KeyAlign {
    case center
    case bottom
    case leading
    case trailing
}

// 标识键帽视觉角色
private enum KeyRole {
    case ordinary
    case function
}

// 提供键盘动态视觉颜色
private enum KeyPalette {
    static let board = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.11, alpha: 0.88)
            : UIColor(white: 0.78, alpha: 0.72)
    }
    static let ordinary = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.39, alpha: 1)
            : UIColor(white: 0.99, alpha: 1)
    }
    static let function = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.25, alpha: 1)
            : UIColor(white: 0.67, alpha: 1)
    }
    static let ordinaryPressed = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.49, alpha: 1)
            : UIColor(white: 0.82, alpha: 1)
    }
    static let functionPressed = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.35, alpha: 1)
            : UIColor(white: 0.57, alpha: 1)
    }
    static let border = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.white.withAlphaComponent(0.42)
    }
    static let shadow = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.88)
            : UIColor.black.withAlphaComponent(0.52)
    }
}

// 描述单个按键
private struct KeySpec {
    let title: String
    let image: String?
    let output: String
    let alternate: String?
    let letter: Bool
    let kind: KeyKind
    let weight: CGFloat
    let enabled: Bool
    let align: KeyAlign
    let fontSize: CGFloat
    let stackIcon: Bool
    let hidKey: MBHIDKey?
    let shiftKey: ShiftKey?

    // 创建按键描述
    init(
        _ title: String = "",
        image: String? = nil,
        output: String = "",
        alternate: String? = nil,
        letter: Bool = false,
        kind: KeyKind = .text,
        weight: CGFloat = 1,
        enabled: Bool = true,
        align: KeyAlign = .center,
        fontSize: CGFloat = 11,
        stackIcon: Bool = false,
        hidKey: MBHIDKey? = nil,
        shiftKey: ShiftKey? = nil
    ) {
        self.title = title
        self.image = image
        self.output = output
        self.alternate = alternate
        self.letter = letter
        self.kind = kind
        self.weight = weight
        self.enabled = enabled
        self.align = align
        self.fontSize = fontSize
        self.stackIcon = stackIcon
        self.hidKey = hidKey
        self.shiftKey = shiftKey
    }
}

// 统一呈现全部键帽视觉与状态
private final class KeyView: UIButton {
    var spec: KeySpec?
    var dragupper: UIView?
    var draglower: UILabel?
    var popup: UIView?
    var hidactive = false
    var fnupper: Bool?
    var touchvalid = false
    var keyRole: KeyRole = .function {
        didSet { setNeedsUpdateConfiguration() }
    }
    var activeTint = UIColor.systemCyan {
        didSet { setNeedsUpdateConfiguration() }
    }
    var appearance = AppearanceConfig.standard {
        didSet { setNeedsUpdateConfiguration() }
    }

    // 创建键帽并接入统一状态刷新
    override init(frame: CGRect) {
        super.init(frame: frame)
        configurationUpdateHandler = { [weak self] _ in
            self?.updvsl()
        }
        layer.masksToBounds = false
    }

    // 禁止从归档创建键帽
    required init?(coder: NSCoder) {
        nil
    }

    // 同步选中态辅助语义
    override var isSelected: Bool {
        didSet {
            if isSelected {
                accessibilityTraits.insert(.selected)
            } else {
                accessibilityTraits.remove(.selected)
            }
            setNeedsUpdateConfiguration()
        }
    }

    // 刷新按压层次
    override var isHighlighted: Bool {
        didSet {
            setNeedsUpdateConfiguration()
            upddpth(animated: !UIAccessibility.isReduceMotionEnabled)
        }
    }

    // 更新键帽阴影路径
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: 7
        ).cgPath
    }

    // 响应系统浅深色变化
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection == nil
            || traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)
        else { return }
        setNeedsUpdateConfiguration()
        upddpth(animated: false)
    }

    // 应用当前键帽语义颜色
    private func updvsl() {
        guard var config = configuration else { return }
        let fill: UIColor
        let custom = appearance.mode == .custom
        if !isEnabled {
            fill = .secondarySystemFill
        } else if isSelected {
            fill = isHighlighted ? activeTint.withAlphaComponent(0.78) : activeTint
        } else {
            fill = switch (keyRole, isHighlighted) {
            case (.ordinary, false): custom ? appearance.key.uiclr : KeyPalette.ordinary
            case (.ordinary, true): custom ? appearance.key.uiclr.withAlphaComponent(0.72) : KeyPalette.ordinaryPressed
            case (.function, false): custom ? appearance.board.uiclr : KeyPalette.function
            case (.function, true): custom ? appearance.board.uiclr.withAlphaComponent(0.72) : KeyPalette.functionPressed
            }
        }
        config.baseForegroundColor = !isEnabled
            ? .tertiaryLabel
            : isSelected ? .white : custom ? appearance.text.uiclr : .label
        config.baseBackgroundColor = fill
        config.cornerStyle = .fixed
        config.background.cornerRadius = 7
        config.background.strokeColor = isSelected
            ? UIColor.white.withAlphaComponent(0.24)
            : KeyPalette.border
        config.background.strokeWidth = 0.5
        configuration = config
        upddpth(animated: false)
    }

    // 应用原生键帽按压深度
    private func upddpth(animated: Bool) {
        let pressed = isHighlighted && isEnabled
        let changes = {
            self.transform = pressed && !UIAccessibility.isReduceMotionEnabled
                ? CGAffineTransform(translationX: 0, y: 1.25).scaledBy(x: 0.995, y: 0.98)
                : .identity
            self.layer.shadowOpacity = pressed ? 0.10 : 0.42
            self.layer.shadowRadius = pressed ? 0.25 : 0.75
            self.layer.shadowOffset = CGSize(width: 0, height: pressed ? 0.5 : 1.75)
            self.traitCollection.performAsCurrent {
                self.layer.shadowColor = KeyPalette.shadow.cgColor
            }
        }
        guard animated else {
            UIView.performWithoutAnimation(changes)
            return
        }
        UIView.animate(
            withDuration: 0.08,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut],
            animations: changes
        )
    }
}

// 启用系统键盘输入点击声
private final class KeyInputView: UIInputView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
}

// 管理键盘扩展界面
final class KeyboardViewController: UIInputViewController {
    private let candidateBar = UIStackView()
    private let preeditLabel = UILabel()
    private let candidateScroll = UIScrollView()
    private let candidateRow = UIStackView()
    private var lexicon: [String: [String]] = [:]
    private var systemCandidates: [String] = []
    private let rows = UIStackView()
    private let trackpad = UIView()
    private weak var blurView: UIVisualEffectView?
    private var settings = SharedConfig.ldcfg()
    private var state = InputState()
    private var modifiers = ModifierState()
    private var modifierLatches = ModifierLatchState()
    private var modifierStarts: [ModifierKey: TimeInterval] = [:]
    private var modifierOwned: Set<ModifierKey> = []
    private var height: NSLayoutConstraint?
    private var candidateTop: NSLayoutConstraint?
    private var candidateLeading: NSLayoutConstraint?
    private var candidateTrailing: NSLayoutConstraint?
    private var rowTop: NSLayoutConstraint?
    private var rowBottom: NSLayoutConstraint?
    private var rowLeading: NSLayoutConstraint?
    private var rowTrailing: NSLayoutConstraint?
    private var buttons: [KeyView] = []
    private let ime = RimeEngine.shared
    private let dragdist: CGFloat = 24
    private let dragreset: TimeInterval = 0.12
    private var cursormotion = CursorMotion(step: 12)
    private var cursorpoint: CGPoint?
    private weak var cursorbutton: KeyView?
    private let speakerPulse = SpeakerPulse()
    private var arrshft: Set<ObjectIdentifier> = []
    // 仅由主 RunLoop 触摸生命周期访问
    nonisolated(unsafe) private var deltimer: Timer?

    // 清理扩展计时器
    deinit {
        NotificationCenter.default.removeObserver(self)
        deltimer?.invalidate()
        HIDBridge.shared.releaseAll()
    }

    // 创建支持系统输入声的键盘根视图
    override func loadView() {
        view = KeyInputView(frame: .zero, inputViewStyle: .keyboard)
    }

    // 构建键盘容器
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = KeyPalette.board
        view.isMultipleTouchEnabled = true
        view.clipsToBounds = false
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(rsthid),
            name: .NSExtensionHostWillResignActive,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(rsthid),
            name: .NSExtensionHostDidEnterBackground,
            object: nil
        )

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.contentView.backgroundColor = KeyPalette.board
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        blurView = blur

        setupCandidateBar(in: blur.contentView)

        rows.axis = .vertical
        rows.alignment = .fill
        rows.distribution = .fillEqually
        rows.spacing = CGFloat(settings.layout.verticalGap)
        rows.clipsToBounds = false
        rows.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(rows)

        trackpad.backgroundColor = .systemGray4
        trackpad.alpha = 0
        trackpad.isHidden = true
        trackpad.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(trackpad)

        height = view.heightAnchor.constraint(equalToConstant: settings.layout.height)
        height?.priority = .init(999)
        height?.isActive = true

        let inset = CGFloat(settings.layout.outerInset)
        candidateTop = candidateBar.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: inset)
        candidateLeading = candidateBar.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: inset)
        candidateTrailing = candidateBar.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -inset)
        rowTop = rows.topAnchor.constraint(equalTo: candidateBar.bottomAnchor, constant: CGFloat(settings.layout.verticalGap))
        rowBottom = rows.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -inset)
        rowLeading = rows.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: inset)
        rowTrailing = rows.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -inset)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            candidateTop!,
            candidateLeading!,
            candidateTrailing!,
            candidateBar.heightAnchor.constraint(equalToConstant: 44),
            rowTop!,
            rowBottom!,
            rowLeading!,
            rowTrailing!,
            trackpad.topAnchor.constraint(equalTo: blur.contentView.topAnchor),
            trackpad.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor),
            trackpad.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor),
            trackpad.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor),
        ])

        applycfg(rebuild: false)
        if settings.chineseEnabled { ime.start(scheme: settings.scheme) }
        loadLexicon()
        renderCandidates(nil)
        bldkbd()
        report()
    }

    // 保持用户指定的键盘高度
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let target = settings.layout.height
        if abs((height?.constant ?? 0) - target) > 1 {
            height?.constant = target
        }
    }

    // 刷新共享设置
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadcfg()
        report()
    }

    // 在输入上下文变化时读取最新共享设置
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        reloadcfg()
        report()
    }

    // 停止离场触摸任务
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopcursor()
        stopdel()
        rsthid()
    }

    // 读取变更后的共享配置并按需重建键盘
    private func reloadcfg() {
        let current = SharedConfig.ldcfg()
        guard current != settings else { return }
        let schemeChanged = current.scheme != settings.scheme
        let enabledChanged = current.chineseEnabled != settings.chineseEnabled
        if !current.chineseEnabled, state.language == .chinese {
            if let snapshot = ime.commit() { applySnapshot(snapshot) }
            state.tgllang()
            renderCandidates(nil)
        }
        settings = current
        if current.chineseEnabled, schemeChanged || enabledChanged {
            ime.start(scheme: current.scheme)
            renderCandidates(nil)
        }
        applycfg(rebuild: true)
    }

    // 应用布局、外观与强调色
    private func applycfg(rebuild: Bool) {
        let appearance = settings.appearance
        view.overrideUserInterfaceStyle = switch appearance.mode {
        case .system, .custom: .unspecified
        case .light: .light
        case .dark: .dark
        }
        let custom = appearance.mode == .custom
        let board = custom ? appearance.board.uiclr : KeyPalette.board
        view.backgroundColor = board
        blurView?.effect = custom ? nil : UIBlurEffect(style: .systemChromeMaterial)
        blurView?.contentView.backgroundColor = board
        rows.spacing = CGFloat(settings.layout.verticalGap)
        let inset = CGFloat(settings.layout.outerInset)
        candidateTop?.constant = inset
        candidateLeading?.constant = inset
        candidateTrailing?.constant = -inset
        rowTop?.constant = CGFloat(settings.layout.verticalGap)
        rowBottom?.constant = -inset
        rowLeading?.constant = inset
        rowTrailing?.constant = -inset
        height?.constant = settings.layout.height
        updateCandidateColors()
        if rebuild { bldkbd() }
    }

    // 回报键盘最近运行与授权状态
    private func report() {
        SharedConfig.svrpt(
            KeyboardReport(
                lastSeen: Date(),
                hasFullAccess: hasFullAccess,
                engineReady: settings.chineseEnabled && ime.ready,
                scheme: settings.scheme
            )
        )
    }

    // 构建拼音预编辑与横向候选栏
    private func setupCandidateBar(in container: UIView) {
        candidateBar.axis = .horizontal
        candidateBar.alignment = .fill
        candidateBar.spacing = 8
        candidateBar.layer.cornerCurve = .continuous
        candidateBar.layer.cornerRadius = 9
        candidateBar.isLayoutMarginsRelativeArrangement = true
        candidateBar.layoutMargins = .init(top: 3, left: 10, bottom: 3, right: 8)
        candidateBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(candidateBar)

        preeditLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        preeditLabel.setContentHuggingPriority(.required, for: .horizontal)
        preeditLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        preeditLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 180).isActive = true
        candidateBar.addArrangedSubview(preeditLabel)

        candidateScroll.showsHorizontalScrollIndicator = false
        candidateScroll.alwaysBounceHorizontal = true
        candidateBar.addArrangedSubview(candidateScroll)

        candidateRow.axis = .horizontal
        candidateRow.alignment = .fill
        candidateRow.spacing = 4
        candidateRow.translatesAutoresizingMaskIntoConstraints = false
        candidateScroll.addSubview(candidateRow)
        NSLayoutConstraint.activate([
            candidateRow.topAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.topAnchor),
            candidateRow.bottomAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.bottomAnchor),
            candidateRow.leadingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.leadingAnchor),
            candidateRow.trailingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.trailingAnchor),
            candidateRow.heightAnchor.constraint(equalTo: candidateScroll.frameLayoutGuide.heightAnchor),
        ])
    }

    // 应用候选栏当前外观
    private func updateCandidateColors() {
        let custom = settings.appearance.mode == .custom
        candidateBar.backgroundColor = custom
            ? settings.appearance.key.uiclr.withAlphaComponent(0.82)
            : .secondarySystemFill
        preeditLabel.textColor = custom ? settings.appearance.text.uiclr : .secondaryLabel
        for case let button as UIButton in candidateRow.arrangedSubviews {
            button.configuration?.baseForegroundColor = custom ? settings.appearance.text.uiclr : .label
        }
    }

    // 读取系统通讯录与文本替换补充词典
    private func loadLexicon() {
        MBLexiconBridge.load(self) { [weak self] grouped in
            guard let self else { return }
            lexicon = grouped
            if state.language == .chinese, ime.isComposing {
                renderCandidates(ime.snapshot())
            }
        }
    }

    // 匹配系统词典中的当前拼音候选
    private func syscands(_ input: String) -> [String] {
        guard !input.isEmpty else { return [] }
        return lexicon
            .filter { $0.key.hasPrefix(input.lowercased()) }
            .sorted { $0.key.count < $1.key.count }
            .flatMap(\.value)
    }

    // 刷新拼音预编辑与候选按钮
    private func renderCandidates(_ snapshot: IMESnapshot?) {
        for item in candidateRow.arrangedSubviews {
            candidateRow.removeArrangedSubview(item)
            item.removeFromSuperview()
        }
        preeditLabel.text = snapshot?.preedit.nonempty
            ?? (state.language == .chinese
                ? ime.ready ? settings.scheme.title : "引擎不可用"
                : "ABC")

        let engineCandidates = Array((snapshot?.candidates ?? []).prefix(20))
        systemCandidates = Array((snapshot.map { syscands($0.rawInput) }?.filter {
            !engineCandidates.contains($0)
        } ?? []).prefix(max(0, 20 - engineCandidates.count)))
        let visible: [(text: String, engineIndex: Int?)] = engineCandidates.enumerated().map {
            (text: $0.element, engineIndex: $0.offset)
        } + systemCandidates.map { (text: $0, engineIndex: nil) }

        for (position, choice) in visible.enumerated() {
            var config = UIButton.Configuration.plain()
            config.title = choice.text
            config.baseForegroundColor = settings.appearance.mode == .custom
                ? settings.appearance.text.uiclr
                : .label
            config.contentInsets = .init(top: 2, leading: 10, bottom: 2, trailing: 10)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 21, weight: position == 0 ? .semibold : .regular)
                return outgoing
            }
            let button = UIButton(configuration: config)
            button.tag = choice.engineIndex ?? -(position - engineCandidates.count + 1)
            button.accessibilityLabel = "候选词 \(choice.text)"
            button.addTarget(self, action: #selector(selectCandidate(_:)), for: .touchUpInside)
            candidateRow.addArrangedSubview(button)
        }
        candidateScroll.setContentOffset(.zero, animated: false)
        updateCandidateColors()
    }

    // 选择当前页候选并写入文本
    @objc private func selectCandidate(_ sender: UIButton) {
        if sender.tag >= 0 {
            guard let snapshot = ime.select(sender.tag) else { return }
            applySnapshot(snapshot)
        } else {
            let index = -sender.tag - 1
            guard systemCandidates.indices.contains(index) else { return }
            ime.reset()
            textDocumentProxy.insertText(systemCandidates[index])
            renderCandidates(nil)
        }
        sndfeed()
    }

    // 提交引擎输出并刷新候选栏
    private func applySnapshot(_ snapshot: IMESnapshot) {
        if !snapshot.commit.isEmpty { textDocumentProxy.insertText(snapshot.commit) }
        renderCandidates(snapshot.composing ? snapshot : nil)
    }

    // 生成固定键盘布局
    private func bldkbd() {
        stopcursor()
        stopdel()
        rsthid()
        buttons.removeAll(keepingCapacity: true)
        for item in rows.arrangedSubviews {
            rows.removeArrangedSubview(item)
            item.removeFromSuperview()
        }

        rows.addArrangedSubview(mkrow(fnrow()))
        for specs in ltrrows() {
            rows.addArrangedSubview(mkrow(specs))
        }
        rows.addArrangedSubview(mkrow(btmrow()))
    }

    // 创建 Mac 双层功能键行
    private func fnrow() -> [KeySpec] {
        [
            ctl("Esc", kind: .escape, weight: 1.5, align: .leading, fontSize: 17),
            ctl("F1", image: "sun.min", kind: .f1, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F2", image: "sun.max", kind: .f2, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F3", image: "rectangle.3.group", kind: .f3, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F4", image: "magnifyingglass", kind: .f4, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F5", image: "mic", kind: .f5, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F6", image: "moon", kind: .f6, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F7", image: "backward", kind: .f7, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F8", image: "playpause", kind: .f8, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F9", image: "forward", kind: .f9, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F10", image: "speaker.slash", kind: .f10, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F11", image: "speaker.wave.1", kind: .f11, align: .bottom, fontSize: 13, stackIcon: true),
            ctl("F12", image: "speaker.wave.3", kind: .f12, align: .bottom, fontSize: 13, stackIcon: true),
            ctl(image: "keyboard.chevron.compact.down", kind: .dismiss),
        ]
    }

    // 创建固定文字键位
    private func ltrrows() -> [[KeySpec]] {
        [
            [
                txt("`", alternate: "~", zhBase: "·"), txt("1", alternate: "!"), txt("2", alternate: "@"),
                txt("3", alternate: "#"), txt("4", alternate: "$", zhAlt: "¥"), txt("5", alternate: "%"),
                txt("6", alternate: "^", zhAlt: "……"), txt("7", alternate: "&"), txt("8", alternate: "*"),
                txt("9", alternate: "("), txt("0", alternate: ")"), txt("-", alternate: "_", zhAlt: "—"),
                txt("=", alternate: "+"), ctl("delete", kind: .delete, weight: 1.7, align: .trailing),
            ],
            [
                ctl("tab", kind: .tab, weight: 1.5, align: .leading, fontSize: 17), ltr("Q"), ltr("W"), ltr("E"), ltr("R"), ltr("T"),
                ltr("Y"), ltr("U"), ltr("I"), ltr("O"), ltr("P"),
                txt("[", alternate: "{", zhBase: "【", zhAlt: "「"),
                txt("]", alternate: "}", zhBase: "】", zhAlt: "」"),
                txt("\\", alternate: "|", weight: 1.5),
            ],
            [
                ctl(
                    settings.chineseEnabled ? (state.language == .english ? imetitle() : "abc") : "abc",
                    kind: .language,
                    weight: 1.8,
                    align: .leading,
                    fontSize: 18
                ),
                ltr("A"), ltr("S"), ltr("D"), ltr("F"), ltr("G"), ltr("H"), ltr("J"), ltr("K"), ltr("L"),
                txt(";", alternate: ":"), txt("'", alternate: "\""),
                ctl("return", kind: .enter, weight: 1.9, align: .trailing),
            ],
            [
                ctl(
                    "shift",
                    kind: .shift,
                    weight: 2.25,
                    align: .leading,
                    hidKey: .leftShift,
                    shiftKey: .left
                ),
                ltr("Z"), ltr("X"), ltr("C"), ltr("V"), ltr("B"), ltr("N"), ltr("M"),
                txt(",", alternate: "<", zhBase: "，", zhAlt: "《"),
                txt(".", alternate: ">", zhBase: "。", zhAlt: "》"), txt("/", alternate: "?"),
                ctl(
                    "shift",
                    kind: .shift,
                    weight: 2.25,
                    align: .trailing,
                    hidKey: .rightShift,
                    shiftKey: .right
                ),
            ],
        ]
    }

    // 创建底部控制行
    private func btmrow() -> [KeySpec] {
        [
            ctl(image: "globe", kind: .next, weight: 1.05, align: .leading),
            ctl("Ctrl", kind: .control, weight: 1.15, align: .leading),
            ctl(image: "option", kind: .leftOption, weight: 1.15, align: .leading),
            ctl(image: "command", kind: .leftCommand, weight: 1.25, align: .leading),
            ctl("space", kind: .space, weight: 5),
            ctl(image: "command", kind: .rightCommand, weight: 1.25, align: .trailing),
            ctl(image: "option", kind: .rightOption, weight: 1.15, align: .trailing),
            ctl(image: "arrowtriangle.left.fill", kind: .leftArrow, weight: 0.75),
            ctl(image: "arrow.up.arrow.down", kind: .upArrow, weight: 0.75),
            ctl(image: "arrowtriangle.right.fill", kind: .rightArrow, weight: 0.75),
        ]
    }

    // 返回当前中文方案的紧凑键帽名称
    private func imetitle() -> String {
        settings.scheme == .fullPinyin ? "全拼" : "双拼"
    }

    // 创建字母按键描述
    private func ltr(_ title: String) -> KeySpec {
        let label = state.uppercase ? title.uppercased() : title.lowercased()
        return KeySpec(
            label,
            output: title.lowercased(),
            letter: true,
            fontSize: 27,
            hidKey: ltrhid(title)
        )
    }

    // 返回字母对应的 USB HID usage
    private func ltrhid(_ value: String) -> MBHIDKey? {
        switch value.lowercased() {
        case "a": .A
        case "b": .B
        case "c": .C
        case "d": .D
        case "e": .E
        case "f": .F
        case "g": .G
        case "h": .H
        case "i": .I
        case "j": .J
        case "k": .K
        case "l": .L
        case "m": .M
        case "n": .N
        case "o": .O
        case "p": .P
        case "q": .Q
        case "r": .R
        case "s": .S
        case "t": .T
        case "u": .U
        case "v": .V
        case "w": .W
        case "x": .X
        case "y": .Y
        case "z": .Z
        default: nil
        }
    }

    // 返回数字与标点对应的 USB HID usage
    private func txthid(_ value: String) -> MBHIDKey? {
        switch value {
        case "1": .digit1
        case "2": .digit2
        case "3": .digit3
        case "4": .digit4
        case "5": .digit5
        case "6": .digit6
        case "7": .digit7
        case "8": .digit8
        case "9": .digit9
        case "0": .digit0
        case "-": .minus
        case "=": .equal
        case "[": .leftBracket
        case "]": .rightBracket
        case "\\": .backslash
        case ";": .semicolon
        case "'": .quote
        case "`": .grave
        case ",": .comma
        case ".": .period
        case "/": .slash
        default: nil
        }
    }

    // 创建中英双层字符按键
    private func txt(
        _ base: String,
        alternate: String? = nil,
        zhBase: String? = nil,
        zhAlt: String? = nil,
        weight: CGFloat = 1
    ) -> KeySpec {
        let chinese = state.language == .chinese
        let output = chinese ? (zhBase ?? base) : base
        let alternate = chinese ? (zhAlt ?? alternate) : alternate
        let label: String
        let size: CGFloat
        if state.shifted, let alternate {
            label = alternate
            size = 27
        } else if let alternate {
            label = "\(alternate)\n\(output)"
            size = 22
        } else {
            label = output
            size = 27
        }
        return KeySpec(
            label,
            output: output,
            alternate: alternate,
            weight: weight,
            fontSize: size,
            hidKey: txthid(base)
        )
    }

    // 创建控制按键描述
    private func ctl(
        _ title: String = "",
        image: String? = nil,
        kind: KeyKind,
        weight: CGFloat = 1,
        align: KeyAlign = .center,
        fontSize: CGFloat = 17,
        stackIcon: Bool = false,
        hidKey: MBHIDKey? = nil,
        shiftKey: ShiftKey? = nil
    ) -> KeySpec {
        KeySpec(
            title,
            image: image,
            kind: kind,
            weight: weight,
            align: align,
            fontSize: fontSize,
            stackIcon: stackIcon,
            hidKey: hidKey,
            shiftKey: shiftKey
        )
    }

    // 创建自适应按键行
    private func mkrow(_ specs: [KeySpec]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fill
        row.spacing = CGFloat(settings.layout.horizontalGap)

        var base: (item: UIView, weight: CGFloat)?
        for spec in specs {
            let item = mkitem(spec)
            row.addArrangedSubview(item)
            if let base {
                item.widthAnchor.constraint(
                    equalTo: base.item.widthAnchor,
                    multiplier: spec.weight / base.weight
                ).isActive = true
            } else {
                base = (item, spec.weight)
            }
        }
        return row
    }

    // 创建普通键帽或上下方向双键
    private func mkitem(_ spec: KeySpec) -> UIView {
        guard spec.image == "arrow.up.arrow.down" else { return mkkey(spec) }

        let pair = UIStackView()
        pair.axis = .vertical
        pair.alignment = .fill
        pair.distribution = .fillEqually
        pair.spacing = 4
        pair.addArrangedSubview(mkkey(ctl(image: "arrowtriangle.up.fill", kind: .upArrow)))
        pair.addArrangedSubview(mkkey(ctl(image: "arrowtriangle.down.fill", kind: .downArrow)))
        return pair
    }

    // 创建单个键帽
    private func mkkey(_ spec: KeySpec) -> KeyView {
        let button = KeyView(type: .system)
        button.spec = spec
        button.keyRole = spec.kind == .text || spec.kind == .space ? .ordinary : .function
        button.activeTint = settings.appearance.accent.uiclr
        button.appearance = settings.appearance
        button.isExclusiveTouch = false
        buttons.append(button)
        button.isEnabled = spec.enabled
        button.accessibilityLabel = aclabel(spec)
        if spec.kind == .placeholder {
            button.accessibilityHint = "任务 3 实现"
        }

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .fixed
        config.title = spec.title.isEmpty ? nil : spec.title
        config.image = spec.image.flatMap(UIImage.init(systemName:))
        config.imagePlacement = spec.stackIcon ? .top : .leading
        config.imagePadding = spec.stackIcon ? 8 : 3
        config.preferredSymbolConfigurationForImage = .init(
            pointSize: spec.kind.isArrow ? 12 : 17,
            weight: .regular
        )
        config.contentInsets = .init(top: 4, leading: 7, bottom: 5, trailing: 7)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: spec.fontSize, weight: .medium)
            return outgoing
        }

        switch spec.align {
        case .center:
            config.titleAlignment = .center
            button.contentHorizontalAlignment = .center
            button.contentVerticalAlignment = .center
        case .bottom:
            config.titleAlignment = .center
            button.contentHorizontalAlignment = .center
            button.contentVerticalAlignment = .bottom
        case .leading:
            config.titleAlignment = .leading
            button.contentHorizontalAlignment = .left
            button.contentVerticalAlignment = .bottom
        case .trailing:
            config.titleAlignment = .trailing
            button.contentHorizontalAlignment = .right
            button.contentVerticalAlignment = .bottom
        }
        if spec.kind.systemKey != nil {
            fnstyle(button, spec: spec, config: &config)
        }

        let selected = (spec.kind == .shift && state.shifted)
            || (spec.kind == .language && state.capsLocked)
            || (spec.kind.modifierKey.map { modifiers.contains($0) } ?? false)
        button.configuration = config
        button.isSelected = selected
        if spec.kind == .shift, selected {
            button.accessibilityValue = state.shiftHeld ? "按住" : "单次启用"
        } else if spec.kind == .language, selected {
            button.accessibilityValue = "大写锁定"
        }
        button.setNeedsUpdateConfiguration()
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center

        if spec.kind.modifierKey != nil {
            button.addTarget(self, action: #selector(moddown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(modtap(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(modcncl(_:)), for: [.touchUpOutside, .touchCancel, .touchDragExit])
        } else if spec.kind.systemKey != nil {
            button.addTarget(self, action: #selector(fndown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(fnup(_:)), for: .touchUpInside)
            button.addTarget(
                self,
                action: #selector(fncncl(_:)),
                for: [.touchUpOutside, .touchCancel, .touchDragExit]
            )
            let drag = UIPanGestureRecognizer(target: self, action: #selector(dragkey(_:)))
            drag.maximumNumberOfTouches = 1
            button.addGestureRecognizer(drag)
        } else if spec.kind == .text {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
            let drag = UIPanGestureRecognizer(target: self, action: #selector(dragkey(_:)))
            drag.maximumNumberOfTouches = 1
            drag.cancelsTouchesInView = true
            drag.delaysTouchesBegan = false
            drag.delaysTouchesEnded = false
            button.addGestureRecognizer(drag)
        } else if spec.kind.isArrow {
            button.addTarget(self, action: #selector(arrdown(_:)), for: .touchDown)
            button.addTarget(
                self,
                action: #selector(arrup(_:)),
                for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
            )
        } else if spec.kind.hidKey != nil {
            button.addTarget(self, action: #selector(hiddown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(hidup(_:)), for: .touchUpInside)
            button.addTarget(
                self,
                action: #selector(hidcncl(_:)),
                for: [.touchUpOutside, .touchCancel, .touchDragExit]
            )
        } else if spec.kind == .space {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
            button.accessibilityHint = "长按并拖动移动光标"
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(crsrdrag(_:)))
            hold.minimumPressDuration = 0.45
            hold.allowableMovement = .greatestFiniteMagnitude
            hold.cancelsTouchesInView = true
            hold.delaysTouchesBegan = false
            hold.delaysTouchesEnded = true
            button.addGestureRecognizer(hold)
        } else if spec.kind == .next {
            button.addTarget(self, action: #selector(rsthid), for: .touchDown)
            button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        } else if spec.kind == .language {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(lngcaps(_:)))
            hold.minimumPressDuration = 0.45
            hold.cancelsTouchesInView = true
            hold.delaysTouchesBegan = false
            button.addGestureRecognizer(hold)
        } else if spec.kind == .dismiss {
            button.accessibilityHint = "长按收起键盘"
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(lngdsmss(_:)))
            hold.minimumPressDuration = 0.45
            hold.cancelsTouchesInView = true
            hold.delaysTouchesBegan = false
            button.addGestureRecognizer(hold)
        } else if spec.kind == .shift {
            button.addTarget(self, action: #selector(shftdown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(shftup(_:)), for: .touchUpInside)
            button.addTarget(
                self,
                action: #selector(shftcncl(_:)),
                for: [.touchUpOutside, .touchCancel, .touchDragExit]
            )
        } else if spec.kind == .delete {
            button.addTarget(self, action: #selector(deldown(_:)), for: .touchDown)
            button.addTarget(
                self,
                action: #selector(delup(_:)),
                for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
            )
        } else if spec.kind != .placeholder {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
        }
        if spec.kind != .placeholder, spec.enabled {
            button.addTarget(self, action: #selector(begkey(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(endkey(_:)), for: .touchUpInside)
            button.addTarget(
                self,
                action: #selector(cnclkey(_:)),
                for: [.touchUpOutside, .touchCancel, .touchDragExit]
            )
        }
        return button
    }

    // 切换功能行上下层图例
    private func fnstyle(
        _ button: KeyView,
        spec: KeySpec,
        config: inout UIButton.Configuration
    ) {
        config.title = state.shifted ? nil : spec.title
        button.contentVerticalAlignment = state.shifted ? .center : .bottom
        button.accessibilityLabel = aclabel(spec)
    }

    // 生成按键辅助标签
    private func aclabel(_ spec: KeySpec) -> String {
        switch spec.kind {
        case .shift: "Shift"
        case .language: settings.chineseEnabled ? "切换输入语言，长按切换 Caps Lock" : "长按切换 Caps Lock"
        case .delete: "删除"
        case .tab: "Tab"
        case .enter: "换行"
        case .space: "空格"
        case .next: "下一个键盘"
        case .dismiss: "收起键盘"
        case .escape: "Esc"
        case .f1: "F1；下滑或 Shift：调低亮度"
        case .f2: "F2；下滑或 Shift：调高亮度"
        case .f3: "F3；下滑或 Shift：显示所有窗口"
        case .f4: "F4；下滑或 Shift：搜索"
        case .f5: "F5；下滑或 Shift：听写"
        case .f6: "F6；下滑或 Shift：切换勿扰模式"
        case .f7: "F7；下滑或 Shift：上一首"
        case .f8: "F8；下滑或 Shift：播放或暂停"
        case .f9: "F9；下滑或 Shift：下一首"
        case .f10: "F10；下滑或 Shift：静音"
        case .f11: "F11；下滑或 Shift：调低音量"
        case .f12: "F12；下滑或 Shift：调高音量"
        case .leftArrow: "左方向键"
        case .rightArrow: "右方向键"
        case .upArrow: "上方向键"
        case .downArrow: "下方向键"
        case .control: "Control"
        case .leftOption: "左 Option"
        case .leftCommand: "左 Command"
        case .rightCommand: "右 Command"
        case .rightOption: "右 Option"
        case .placeholder: spec.title.isEmpty ? "任务 3 功能键" : "\(spec.title)，任务 3 功能键"
        case .text: spec.title
        }
    }

    // 开始统一按键触摸与即时反馈
    @objc private func begkey(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            let spec = button.spec,
            button.isEnabled
        else { return }
        button.touchvalid = true
        if spec.kind == .text { shwpop(button, spec: spec) }
        sndfeed()
    }

    // 完成统一按键触摸并恢复弹出层
    @objc private func endkey(_ sender: UIButton) {
        guard let button = sender as? KeyView else { return }
        button.touchvalid = false
        hidepop(button)
    }

    // 取消滑出键帽的统一按键触摸
    @objc private func cnclkey(_ sender: UIButton) {
        guard let button = sender as? KeyView else { return }
        button.touchvalid = false
        hidepop(button)
    }

    // 播放系统输入声与轻触反馈
    private func sndfeed(haptic: Bool = true) {
        if settings.keySound { UIDevice.current.playInputClick() }
        guard haptic else { return }
        speakerPulse.play(
            enabled: settings.simulatedHaptics,
            fullAccess: hasFullAccess,
            intensity: settings.hapticIntensity
        )
    }

    // 显示普通字符键弹出反馈
    private func shwpop(_ button: KeyView, spec: KeySpec) {
        hidepop(button)
        let keyframe = button.convert(button.bounds, to: view)
        let width = min(max(keyframe.width * 1.18, 54), 82)
        let height = min(max(keyframe.height * 1.35, 62), 84)
        let maxx = max(4, view.bounds.width - width - 4)
        let origin = CGPoint(
            x: min(max(keyframe.midX - width / 2, 4), maxx),
            y: max(4, keyframe.minY - height + 8)
        )
        let popup = UIView(frame: CGRect(origin: origin, size: CGSize(width: width, height: height)))
        let custom = settings.appearance.mode == .custom
        popup.backgroundColor = custom ? settings.appearance.key.uiclr : KeyPalette.ordinary
        popup.isUserInteractionEnabled = false
        popup.isAccessibilityElement = false
        popup.layer.cornerCurve = .continuous
        popup.layer.cornerRadius = 10
        popup.layer.borderWidth = 0.5
        popup.layer.borderColor = KeyPalette.border.resolvedColor(with: traitCollection).cgColor
        popup.layer.shadowColor = KeyPalette.shadow.resolvedColor(with: traitCollection).cgColor
        popup.layer.shadowOpacity = 0.42
        popup.layer.shadowRadius = 2
        popup.layer.shadowOffset = CGSize(width: 0, height: 2)
        popup.layer.shadowPath = UIBezierPath(roundedRect: popup.bounds, cornerRadius: 10).cgPath

        let label = UILabel(frame: popup.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.font = .systemFont(ofSize: 34, weight: .medium)
        label.text = poptxt(spec)
        label.textAlignment = .center
        label.textColor = custom ? settings.appearance.text.uiclr : .label
        label.isUserInteractionEnabled = false
        label.isAccessibilityElement = false
        popup.addSubview(label)

        button.popup = popup
        view.addSubview(popup)
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(
            withDuration: 0.06,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            popup.alpha = 1
            popup.transform = .identity
        }
    }

    // 移除普通字符键弹出反馈
    private func hidepop(_ button: KeyView) {
        button.popup?.layer.removeAllAnimations()
        button.popup?.removeFromSuperview()
        button.popup = nil
    }

    // 生成当前字符键弹出文本
    private func poptxt(_ spec: KeySpec) -> String {
        if spec.letter {
            return state.uppercase ? spec.output.uppercased() : spec.output.lowercased()
        }
        return state.shifted ? (spec.alternate ?? spec.output) : spec.output
    }

    // 处理全部可用按键
    @objc private func prskey(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            button.touchvalid,
            let spec = button.spec
        else { return }
        if spec.kind != .shift { state.shftuse() }
        switch spec.kind {
        case .text:
            inptxt(spec, drag: false)
        case .shift:
            state.tglshft()
            rfrshft()
        case .language:
            guard settings.chineseEnabled else { return }
            if state.language == .chinese, let snapshot = ime.commit() {
                applySnapshot(snapshot)
            }
            state.tgllang()
            if state.language == .chinese { ime.start(scheme: settings.scheme) }
            renderCandidates(nil)
            bldkbd()
        case .delete:
            break
        case .enter:
            if modifiers.isActive {
                sndhid(.enter)
            } else if state.language == .chinese,
                      ime.isComposing,
                      let snapshot = ime.command(0xFF0D) {
                applySnapshot(snapshot)
            } else {
                textDocumentProxy.insertText("\n")
            }
        case .space:
            if modifiers.isActive {
                sndhid(.space)
            } else if state.language == .chinese,
                      ime.isComposing,
                      let snapshot = ime.input(" ") {
                applySnapshot(snapshot)
            } else {
                textDocumentProxy.insertText(" ")
            }
        case .dismiss:
            break
        case .tab, .escape, .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12,
             .leftArrow, .rightArrow, .upArrow, .downArrow,
             .control, .leftOption, .leftCommand, .rightCommand, .rightOption:
            break
        case .next, .placeholder:
            break
        }
    }

    // 通过当前输入路径发送字符键
    private func inptxt(_ spec: KeySpec, drag: Bool) {
        if modifiers.isActive {
            if let key = spec.hidKey { sndhid(key) }
            return
        }
        let shifted = state.shifted
        let output = drag
            ? state.dragout(spec.output, alternate: spec.alternate, letter: spec.letter)
            : state.emit(spec.output, alternate: spec.alternate, letter: spec.letter)
        if state.language == .chinese, !shifted, !drag {
            if output.unicodeScalars.allSatisfy(\.isASCII), let snapshot = ime.input(output) {
                applySnapshot(snapshot)
                if shifted != state.shifted { rfrshft() }
                return
            }
            if ime.isComposing, let snapshot = ime.commit() { applySnapshot(snapshot) }
        }
        textDocumentProxy.insertText(output)
        if shifted != state.shifted { rfrshft() }
    }

    // 记录待提交的 HID 特殊键
    @objc private func hiddown(_ sender: UIButton) {
        guard let button = sender as? KeyView else { return }
        button.hidactive = true
    }

    // 提交键帽内抬起的 HID 特殊键
    @objc private func hidup(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            button.hidactive,
            button.touchvalid,
            let key = button.spec?.kind.hidKey
        else { return }
        button.hidactive = false
        sndhid(key)
    }

    // 取消滑出键帽的 HID 特殊键
    @objc private func hidcncl(_ sender: UIButton) {
        (sender as? KeyView)?.hidactive = false
    }

    // 按下方向键并保持 HID 自动重复
    @objc private func arrdown(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            !button.hidactive,
            let key = button.spec?.kind.hidKey
        else { return }
        if state.shifted, !state.shiftHeld {
            if arrshft.isEmpty, !HIDBridge.shared.keyDown(.leftShift) { return }
            arrshft.insert(ObjectIdentifier(button))
        }
        guard HIDBridge.shared.keyDown(key) else {
            if !relarrshft(button) { rsthid() }
            return
        }
        button.hidactive = true
        state.shftuse()
    }

    // 释放方向键并停止 HID 自动重复
    @objc private func arrup(_ sender: UIButton) {
        guard let button = sender as? KeyView else { return }
        let key = button.spec?.kind.hidKey
        let keysent = !button.hidactive || key.map(HIDBridge.shared.keyUp) == true
        button.hidactive = false
        let shiftsent = relarrshft(button)
        guard keysent, shiftsent else {
            rsthid()
            return
        }
        consumeOnce()
        updmods()
    }

    // 释放轻点锁定产生的方向键 Shift
    private func relarrshft(_ button: KeyView) -> Bool {
        guard arrshft.remove(ObjectIdentifier(button)) != nil else { return true }
        let leftheld = buttons.contains { item in
            item.hidactive && item.spec?.kind == .shift && item.spec?.hidKey == .leftShift
        }
        guard arrshft.isEmpty, !leftheld else { return true }
        return HIDBridge.shared.keyUp(.leftShift)
    }

    // 记录功能键轻点选择层
    @objc private func fndown(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            button.spec?.kind.systemKey != nil
        else { return }
        button.fnupper = state.shifted
        if state.shiftHeld { state.shftuse() }
    }

    // 完成功能键轻点
    @objc private func fnup(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            let spec = button.spec,
            let upper = button.fnupper
        else { return }
        button.fnupper = nil
        sndfn(spec, upper: upper)
    }

    // 取消功能键轻点
    @objc private func fncncl(_ sender: UIButton) {
        (sender as? KeyView)?.fnupper = nil
    }

    // 开始物理修饰键触摸
    @objc private func moddown(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            let spec = button.spec,
            let modifier = spec.kind.modifierKey,
            let key = spec.kind.hidKey
        else { return }
        modifierStarts[modifier] = CACurrentMediaTime()
        guard !modifiers.contains(modifier) else {
            updmods()
            return
        }
        guard modifiers.press(modifier) else { return }
        modifierOwned.insert(modifier)
        state.shftuse()
        guard HIDBridge.shared.keyDown(key) else {
            modifierOwned.remove(modifier)
            modifiers.release(modifier)
            updmods()
            return
        }
        updmods()
    }

    // 完成修饰键单击
    @objc private func modtap(_ sender: UIButton) {
        guard
            let spec = (sender as? KeyView)?.spec,
            let modifier = spec.kind.modifierKey,
            let key = spec.kind.hidKey
        else { return }
        let now = CACurrentMediaTime()
        let held = now - (modifierStarts.removeValue(forKey: modifier) ?? now)
        let action = modifierLatches.tap(
            modifier,
            sticky: settings.stickyModifiers,
            mode: settings.modifierMode,
            heldFor: held,
            at: now
        )
        switch action {
        case .release:
            modifierOwned.remove(modifier)
            if !relmod(modifier, key: key) { return }
        case .keepOnce, .keepLocked:
            modifierOwned.remove(modifier)
        }
        updmods()
    }

    // 取消修饰键触摸
    @objc private func modcncl(_ sender: UIButton) {
        guard
            let spec = (sender as? KeyView)?.spec,
            let modifier = spec.kind.modifierKey,
            let key = spec.kind.hidKey
        else { return }
        modifierStarts[modifier] = nil
        guard modifierOwned.remove(modifier) != nil else { return }
        guard relmod(modifier, key: key) else { return }
        updmods()
    }

    // 释放指定修饰键并收敛 HID 失败
    private func relmod(_ modifier: ModifierKey, key: MBHIDKey) -> Bool {
        guard modifiers.release(modifier) else { return true }
        guard HIDBridge.shared.keyUp(key) else {
            rsthid()
            return false
        }
        return true
    }

    // 释放已被普通按键消费的单次修饰键
    private func consumeOnce() {
        for modifier in modifierLatches.consumeOnce() {
            guard let key = modhid(modifier) else { continue }
            if !relmod(modifier, key: key) { return }
        }
        updmods()
    }

    // 返回共享修饰键对应的 HID usage
    private func modhid(_ modifier: ModifierKey) -> MBHIDKey? {
        switch modifier {
        case .control: .control
        case .leftOption: .leftOption
        case .leftCommand: .leftCommand
        case .rightCommand: .rightCommand
        case .rightOption: .rightOption
        }
    }

    // 刷新全部修饰键活动外观
    private func updmods() {
        for button in buttons {
            guard
                let spec = button.spec,
                let modifier = spec.kind.modifierKey
            else { continue }
            let active = modifiers.contains(modifier)
            button.isSelected = active
            button.accessibilityValue = switch modifierLatches.stage(modifier) {
            case .inactive: active ? "按住" : nil
            case .once: "下一键"
            case .locked: "持续锁定"
            }
        }
    }

    // 处理空格键触控板手势
    @objc private func crsrdrag(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            begcursor(sender)
        case .changed:
            movecursor(sender)
        case .ended:
            movecursor(sender)
            stopcursor()
        case .cancelled, .failed:
            stopcursor()
        default:
            break
        }
    }

    // 开始全键盘触控板状态
    private func begcursor(_ sender: UILongPressGestureRecognizer) {
        guard let button = sender.view as? KeyView else { return }
        state.shftuse()
        for key in buttons {
            key.touchvalid = false
            hidepop(key)
        }
        cursormotion.reset()
        cursorpoint = sender.location(in: view)
        cursorbutton = button
        button.accessibilityValue = "光标移动"
        rows.accessibilityElementsHidden = true
        trackpad.layer.removeAllAnimations()
        trackpad.isHidden = false
        if UIAccessibility.isReduceMotionEnabled {
            trackpad.alpha = 1
        } else {
            trackpad.alpha = 0
            UIView.animate(withDuration: 0.15) {
                self.trackpad.alpha = 1
            }
        }
    }

    // 将拖动位移转换为成对 HID 方向事件
    private func movecursor(_ sender: UILongPressGestureRecognizer) {
        guard let previous = cursorpoint else { return }
        let current = sender.location(in: view)
        cursorpoint = current
        let directions = cursormotion.move(
            x: Double(current.x - previous.x),
            y: Double(current.y - previous.y)
        )
        for direction in directions {
            sendcursor(direction)
        }
    }

    // 发送一次完整光标方向按键
    private func sendcursor(_ direction: CursorDirection) {
        let key: MBHIDKey = switch direction {
        case .left: .leftArrow
        case .right: .rightArrow
        case .up: .upArrow
        case .down: .downArrow
        }
        sndhid(key)
    }

    // 发送一次完整 HID 按键
    @discardableResult
    private func sndhid(_ key: MBHIDKey) -> Bool {
        guard HIDBridge.shared.keyDown(key) else { return false }
        state.shftuse()
        guard HIDBridge.shared.keyUp(key) else {
            rsthid()
            return false
        }
        consumeOnce()
        updmods()
        return true
    }

    // 发送一次完整功能键动作
    @discardableResult
    private func sndfn(_ spec: KeySpec, upper: Bool) -> Bool {
        let sent: Bool
        if upper, let system = spec.kind.systemKey {
            guard HIDBridge.shared.systemKeyDown(system) else { return false }
            sent = HIDBridge.shared.systemKeyUp(system)
        } else if let key = spec.kind.hidKey {
            guard HIDBridge.shared.keyDown(key) else { return false }
            sent = HIDBridge.shared.keyUp(key)
        } else {
            return false
        }
        guard sent else {
            rsthid()
            return false
        }
        state.usefn()
        consumeOnce()
        rfrshft()
        updmods()
        return true
    }

    // 释放全部 HID 与本地触摸状态
    @objc private func rsthid() {
        stopcursor()
        stopdel()
        state.shftcncl()
        modifiers.reset()
        modifierLatches.reset()
        modifierStarts.removeAll()
        modifierOwned.removeAll()
        for button in buttons {
            button.hidactive = false
            button.fnupper = nil
            button.touchvalid = false
            hidepop(button)
        }
        arrshft.removeAll()
        HIDBridge.shared.releaseAll()
        rfrshft()
        updmods()
    }

    // 结束触控板状态并恢复键盘
    private func stopcursor() {
        cursormotion.reset()
        cursorpoint = nil
        cursorbutton?.accessibilityValue = nil
        cursorbutton = nil
        rows.accessibilityElementsHidden = false
        trackpad.layer.removeAllAnimations()
        trackpad.alpha = 0
        trackpad.isHidden = true
    }

    // 处理语言键长按 Caps Lock
    @objc private func lngcaps(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        state.tglcaps()
        sndfeed()
        bldkbd()
    }

    // 处理收起键盘长按
    @objc private func lngdsmss(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        rsthid()
        dismissKeyboard()
    }

    // 开始 Shift 触摸
    @objc private func shftdown(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            let spec = button.spec,
            let shift = spec.shiftKey,
            let key = spec.hidKey
        else { return }
        state.shftdown(shift)
        button.hidactive = HIDBridge.shared.keyDown(key)
        rfrshft()
    }

    // 完成 Shift 触摸
    @objc private func shftup(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            let spec = button.spec,
            let shift = spec.shiftKey,
            let key = spec.hidKey
        else { return }
        if button.hidactive {
            button.hidactive = false
            if !HIDBridge.shared.keyUp(key) {
                rsthid()
                return
            }
        }
        state.shftup(shift)
        rfrshft()
    }

    // 取消 Shift 触摸
    @objc private func shftcncl(_ sender: UIButton) {
        guard
            let button = sender as? KeyView,
            let spec = button.spec,
            let shift = spec.shiftKey,
            let key = spec.hidKey
        else { return }
        if button.hidactive {
            button.hidactive = false
            if !HIDBridge.shared.keyUp(key) {
                rsthid()
                return
            }
        }
        state.shftcncl(shift)
        rfrshft()
    }

    // 刷新 Shift 键帽状态
    private func rfrshft() {
        for button in buttons {
            guard let spec = button.spec, var config = button.configuration else { continue }
            if spec.kind == .text {
                let legend = keylegend(spec)
                config.title = legend.title
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var outgoing = incoming
                    outgoing.font = .systemFont(ofSize: legend.size, weight: .medium)
                    return outgoing
                }
                button.accessibilityLabel = legend.title
            } else if spec.kind == .shift {
                button.isSelected = state.shifted
                button.accessibilityValue = state.shifted
                    ? state.shiftHeld ? "按住" : "单次启用"
                    : nil
            } else if spec.kind.systemKey != nil {
                fnstyle(button, spec: spec, config: &config)
            } else {
                continue
            }
            button.configuration = config
            if button.dragupper != nil {
                button.titleLabel?.alpha = 0
                button.imageView?.alpha = 0
            }
        }
    }

    // 生成当前字符键图例
    private func keylegend(_ spec: KeySpec) -> (title: String, size: CGFloat) {
        if spec.letter {
            return (state.uppercase ? spec.output.uppercased() : spec.output.lowercased(), 27)
        }
        if state.shifted, let alternate = spec.alternate {
            return (alternate, 27)
        }
        if let alternate = spec.alternate {
            return ("\(alternate)\n\(spec.output)", 22)
        }
        return (spec.output, 27)
    }

    // 开始 Delete 删除与延迟
    @objc private func deldown(_ sender: UIButton) {
        stopdel()
        state.shftuse()
        if modifiers.isActive {
            sndhid(.delete)
            return
        }
        if state.language == .chinese,
           ime.isComposing,
           let snapshot = ime.command(0xFF08) {
            applySnapshot(snapshot)
            return
        }
        textDocumentProxy.deleteBackward()
        let timer = Timer(timeInterval: 0.45, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.startdel()
            }
        }
        deltimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    // 启动 Delete 连续删除
    private func startdel() {
        guard deltimer != nil else { return }
        deltimer?.invalidate()
        textDocumentProxy.deleteBackward()
        sndfeed(haptic: false)
        let timer = Timer(timeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.deltick()
            }
        }
        deltimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    // 执行 Delete 连续删除
    private func deltick() {
        guard deltimer?.isValid == true else { return }
        textDocumentProxy.deleteBackward()
        sndfeed(haptic: false)
    }

    // 处理 Delete 触摸终止
    @objc private func delup(_ sender: UIButton) {
        stopdel()
    }

    // 停止 Delete 计时器
    private func stopdel() {
        deltimer?.invalidate()
        deltimer = nil
    }

    // 处理字符键下拖
    @objc private func dragkey(_ sender: UIPanGestureRecognizer) {
        guard let button = sender.view as? KeyView, let spec = button.spec else { return }
        let distance = max(sender.translation(in: button).y, 0)

        switch sender.state {
        case .began:
            button.touchvalid = false
            hidepop(button)
            begdrag(button, spec: spec)
            upddrag(button, spec: spec, distance: distance)
        case .changed:
            if button.dragupper == nil { begdrag(button, spec: spec) }
            upddrag(button, spec: spec, distance: distance)
        case .ended:
            if distance >= dragdist {
                if spec.kind.systemKey != nil {
                    sndfn(spec, upper: true)
                } else {
                    inptxt(spec, drag: true)
                }
            }
            rstdrag(button, spec: spec, animated: !UIAccessibility.isReduceMotionEnabled)
        case .cancelled, .failed:
            rstdrag(button, spec: spec, animated: !UIAccessibility.isReduceMotionEnabled)
        default:
            break
        }
    }

    // 创建下拖临时图例
    private func begdrag(_ button: KeyView, spec: KeySpec) {
        clrdrag(button)
        let function = spec.kind.systemKey != nil
        let upper: UIView
        if function, let image = spec.image {
            upper = mkdragimg(image, button: button)
        } else {
            upper = mkdraglbl(
                spec.letter ? spec.output.uppercased() : (spec.alternate ?? spec.output),
                size: spec.letter ? 27 : (spec.alternate == nil ? 27 : 22),
                button: button
            )
        }
        let lower = mkdraglbl(
            function
                ? spec.title
                : spec.letter
                ? (state.uppercase ? spec.output.uppercased() : spec.output.lowercased())
                : spec.output,
            size: function ? spec.fontSize : (spec.letter ? 27 : (spec.alternate == nil ? 27 : 22)),
            button: button
        )
        button.dragupper = upper
        button.draglower = lower
        button.addSubview(upper)
        button.addSubview(lower)
        button.titleLabel?.alpha = 0
        button.imageView?.alpha = 0
    }

    // 更新下拖临时图例
    private func upddrag(_ button: KeyView, spec: KeySpec, distance: CGFloat) {
        guard let upper = button.dragupper, let lower = button.draglower else { return }
        let progress = min(distance / dragdist, 1)
        let offset = min(11, button.bounds.height * 0.22)
        if spec.kind.systemKey != nil, state.shifted {
            upper.transform = .identity
            lower.transform = CGAffineTransform(
                translationX: 0,
                y: offset
            ).scaledBy(x: 0.55, y: 0.55)
            lower.alpha = 0
            return
        }
        let upperScale = spec.kind.systemKey != nil || spec.letter || spec.alternate == nil
            ? 1
            : 1 + ((27 / 22) - 1) * progress
        let lowerScale = 1 - (0.45 * progress)
        upper.transform = CGAffineTransform(
            translationX: 0,
            y: -offset * (1 - progress)
        ).scaledBy(x: upperScale, y: upperScale)
        lower.transform = CGAffineTransform(
            translationX: 0,
            y: offset
        ).scaledBy(x: lowerScale, y: lowerScale)
        lower.alpha = 1 - progress
    }

    // 复位下拖临时图例
    private func rstdrag(_ button: KeyView, spec: KeySpec, animated: Bool) {
        guard let upper = button.dragupper, let lower = button.draglower else {
            button.titleLabel?.alpha = 1
            return
        }
        let offset = min(11, button.bounds.height * 0.22)
        let restore = {
            if spec.kind.systemKey != nil {
                upper.transform = self.state.shifted
                    ? .identity
                    : CGAffineTransform(translationX: 0, y: -offset)
                upper.alpha = 1
                lower.transform = self.state.shifted
                    ? CGAffineTransform(translationX: 0, y: offset).scaledBy(x: 0.55, y: 0.55)
                    : CGAffineTransform(translationX: 0, y: offset)
                lower.alpha = self.state.shifted ? 0 : 1
            } else if spec.letter {
                upper.transform = self.state.uppercase
                    ? .identity
                    : CGAffineTransform(translationX: 0, y: -offset)
                upper.alpha = self.state.uppercase ? 1 : 0
                lower.transform = self.state.uppercase
                    ? CGAffineTransform(translationX: 0, y: offset)
                    : .identity
                lower.alpha = self.state.uppercase ? 0 : 1
            } else if self.state.shifted {
                let scale: CGFloat = spec.alternate == nil ? 1 : 27 / 22
                upper.transform = CGAffineTransform(scaleX: scale, y: scale)
                upper.alpha = 1
                lower.alpha = 0
            } else {
                upper.transform = CGAffineTransform(translationX: 0, y: -offset)
                upper.alpha = 1
                lower.transform = CGAffineTransform(translationX: 0, y: offset)
                lower.alpha = 1
            }
        }
        let finish: (Bool) -> Void = { _ in
            guard button.dragupper === upper, button.draglower === lower else { return }
            self.clrdrag(button)
        }
        guard animated else {
            restore()
            finish(true)
            return
        }
        UIView.animate(
            withDuration: dragreset,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut],
            animations: restore,
            completion: finish
        )
    }

    // 创建不可交互图例标签
    private func mkdraglbl(_ text: String, size: CGFloat, button: KeyView) -> UILabel {
        let label = UILabel(frame: button.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.font = .systemFont(ofSize: size, weight: .medium)
        label.text = text
        label.textAlignment = .center
        label.textColor = settings.appearance.mode == .custom ? settings.appearance.text.uiclr : .label
        label.isUserInteractionEnabled = false
        label.isAccessibilityElement = false
        return label
    }

    // 创建不可交互图标视图
    private func mkdragimg(_ name: String, button: KeyView) -> UIImageView {
        let image = UIImageView(frame: button.bounds)
        image.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        image.image = UIImage(systemName: name)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        )
        image.contentMode = .center
        image.tintColor = settings.appearance.mode == .custom ? settings.appearance.text.uiclr : .label
        image.isUserInteractionEnabled = false
        image.isAccessibilityElement = false
        return image
    }

    // 移除下拖临时图例
    private func clrdrag(_ button: KeyView) {
        button.dragupper?.layer.removeAllAnimations()
        button.draglower?.layer.removeAllAnimations()
        button.dragupper?.removeFromSuperview()
        button.draglower?.removeFromSuperview()
        button.dragupper = nil
        button.draglower = nil
        button.titleLabel?.alpha = 1
        button.imageView?.alpha = 1
    }
}

// 转换共享主题颜色
private extension ThemeColor {
    var uiclr: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// 将空字符串转换为空值
private extension String {
    var nonempty: String? {
        isEmpty ? nil : self
    }
}
