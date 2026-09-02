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
}

// 标识键帽内容对齐
private enum KeyAlign {
    case center
    case bottom
    case leading
    case trailing
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

// 保存按键描述
private final class BoardButton: UIButton {
    var spec: KeySpec?
    var dragupper: UIView?
    var draglower: UILabel?
    var hidactive = false
    var fnupper: Bool?
}

// 管理键盘扩展界面
final class KeyboardViewController: UIInputViewController {
    private let rows = UIStackView()
    private let trackpad = UIView()
    private var theme = SharedConfig.ldthm()
    private var state = InputState()
    private var modifiers = ModifierState()
    private var height: NSLayoutConstraint?
    private var buttons: [BoardButton] = []
    private let dragdist: CGFloat = 24
    private let dragreset: TimeInterval = 0.12
    private var cursormotion = CursorMotion(step: 12)
    private var cursorpoint: CGPoint?
    private weak var cursorbutton: BoardButton?
    // 仅由主 RunLoop 触摸生命周期访问
    nonisolated(unsafe) private var deltimer: Timer?

    // 清理扩展计时器
    deinit {
        NotificationCenter.default.removeObserver(self)
        deltimer?.invalidate()
        HIDBridge.shared.releaseAll()
    }

    // 构建键盘容器
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
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

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)

        rows.axis = .vertical
        rows.alignment = .fill
        rows.distribution = .fillEqually
        rows.spacing = 6
        rows.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(rows)

        trackpad.backgroundColor = .systemGray4
        trackpad.alpha = 0
        trackpad.isHidden = true
        trackpad.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(trackpad)

        height = view.heightAnchor.constraint(equalToConstant: 390)
        height?.priority = .init(999)
        height?.isActive = true

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rows.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 8),
            rows.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -8),
            rows.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 8),
            rows.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -8),
            trackpad.topAnchor.constraint(equalTo: blur.contentView.topAnchor),
            trackpad.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor),
            trackpad.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor),
            trackpad.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor),
        ])

        bldkbd()
    }

    // 适配可用键盘宽度
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let target = min(max(view.bounds.width * 0.5, 340), 430)
        if abs((height?.constant ?? 0) - target) > 1 {
            height?.constant = target
        }
    }

    // 刷新共享主题
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theme = SharedConfig.ldthm()
        bldkbd()
    }

    // 停止离场触摸任务
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopcursor()
        stopdel()
        rsthid()
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
                ctl(state.language == .english ? "双拼" : "abc", kind: .language, weight: 1.8, align: .leading, fontSize: 18),
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
            ctl(image: "arrow.left", kind: .leftArrow, weight: 0.75),
            ctl(image: "arrow.up.arrow.down", kind: .upArrow, weight: 0.75),
            ctl(image: "arrow.right", kind: .rightArrow, weight: 0.75),
        ]
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
        row.spacing = 5

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
        pair.spacing = 3
        pair.addArrangedSubview(mkkey(ctl(image: "arrow.up", kind: .upArrow)))
        pair.addArrangedSubview(mkkey(ctl(image: "arrow.down", kind: .downArrow)))
        return pair
    }

    // 创建单个键帽
    private func mkkey(_ spec: KeySpec) -> BoardButton {
        let button = BoardButton(type: .system)
        button.spec = spec
        buttons.append(button)
        button.isEnabled = spec.enabled
        button.accessibilityLabel = aclabel(spec)
        if spec.kind == .placeholder {
            button.accessibilityHint = "任务 3 实现"
        }

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.title = spec.title.isEmpty ? nil : spec.title
        config.image = spec.image.flatMap(UIImage.init(systemName:))
        config.imagePlacement = spec.stackIcon ? .top : .leading
        config.imagePadding = spec.stackIcon ? 8 : 3
        config.preferredSymbolConfigurationForImage = .init(pointSize: 17, weight: .regular)
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
        if spec.kind == .placeholder {
            config.baseForegroundColor = .tertiaryLabel
            config.baseBackgroundColor = .secondarySystemFill
        } else if selected {
            config.baseForegroundColor = .systemBackground
            config.baseBackgroundColor = theme.primary.uiclr
        } else if spec.kind == .text || spec.kind == .space {
            config.baseForegroundColor = .label
            config.baseBackgroundColor = theme.primary.uiclr.withAlphaComponent(0.18)
        } else {
            config.baseForegroundColor = .label
            config.baseBackgroundColor = theme.accent.uiclr.withAlphaComponent(0.24)
        }
        button.configuration = config
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
        } else if spec.kind.hidKey != nil {
            button.addTarget(self, action: #selector(hiddown(_:)), for: .touchDown)
            button.addTarget(
                self,
                action: #selector(hidup(_:)),
                for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
            )
        } else if spec.kind == .space {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
            button.accessibilityHint = "长按并拖动移动光标"
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(crsrdrag(_:)))
            hold.minimumPressDuration = 0.45
            hold.allowableMovement = .greatestFiniteMagnitude
            hold.cancelsTouchesInView = true
            hold.delaysTouchesEnded = true
            button.addGestureRecognizer(hold)
        } else if spec.kind == .next {
            button.addTarget(self, action: #selector(rsthid), for: .touchDown)
            button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        } else if spec.kind == .language {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(lngcaps(_:)))
            hold.minimumPressDuration = 0.45
            button.addGestureRecognizer(hold)
        } else if spec.kind == .shift {
            button.addTarget(self, action: #selector(shftdown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(shftup(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(shftcncl(_:)), for: [.touchUpOutside, .touchCancel])
        } else if spec.kind == .delete {
            button.addTarget(self, action: #selector(deldown(_:)), for: .touchDown)
            button.addTarget(
                self,
                action: #selector(delup(_:)),
                for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
            )
        } else if spec.kind == .text {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
            let drag = UIPanGestureRecognizer(target: self, action: #selector(dragkey(_:)))
            drag.maximumNumberOfTouches = 1
            button.addGestureRecognizer(drag)
        } else if spec.kind != .placeholder {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
        }
        return button
    }

    // 切换功能行上下层图例
    private func fnstyle(
        _ button: BoardButton,
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
        case .language: "切换输入语言，长按切换 Caps Lock"
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

    // 处理全部可用按键
    @objc private func prskey(_ sender: UIButton) {
        guard let spec = (sender as? BoardButton)?.spec else { return }
        if spec.kind != .shift { state.shftuse() }
        switch spec.kind {
        case .text:
            inptxt(spec, drag: false)
        case .shift:
            state.tglshft()
            rfrshft()
        case .language:
            state.tgllang()
            bldkbd()
        case .delete:
            break
        case .enter:
            if modifiers.isActive {
                sndhid(.enter)
            } else {
                textDocumentProxy.insertText("\n")
            }
        case .space:
            if modifiers.isActive {
                sndhid(.space)
            } else {
                textDocumentProxy.insertText(" ")
            }
        case .dismiss:
            rsthid()
            dismissKeyboard()
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
        let output = drag
            ? state.dragout(spec.output, alternate: spec.alternate, letter: spec.letter)
            : state.emit(spec.output, alternate: spec.alternate, letter: spec.letter)
        textDocumentProxy.insertText(output)
        rfrshft()
    }

    // 发送 HID 按键按下事件
    @objc private func hiddown(_ sender: UIButton) {
        guard
            let button = sender as? BoardButton,
            let key = button.spec?.kind.hidKey
        else { return }
        guard HIDBridge.shared.keyDown(key) else { return }
        button.hidactive = true
        state.shftuse()
    }

    // 发送 HID 按键抬起事件
    @objc private func hidup(_ sender: UIButton) {
        guard
            let button = sender as? BoardButton,
            button.hidactive
        else { return }
        button.hidactive = false
        guard
            let key = button.spec?.kind.hidKey,
            HIDBridge.shared.keyUp(key)
        else {
            rsthid()
            return
        }
        updmods()
    }

    // 记录功能键轻点选择层
    @objc private func fndown(_ sender: UIButton) {
        guard
            let button = sender as? BoardButton,
            button.spec?.kind.systemKey != nil
        else { return }
        button.fnupper = state.shifted
        if state.shiftHeld { state.shftuse() }
    }

    // 完成功能键轻点
    @objc private func fnup(_ sender: UIButton) {
        guard
            let button = sender as? BoardButton,
            let spec = button.spec,
            let upper = button.fnupper
        else { return }
        button.fnupper = nil
        sndfn(spec, upper: upper)
    }

    // 取消功能键轻点
    @objc private func fncncl(_ sender: UIButton) {
        (sender as? BoardButton)?.fnupper = nil
    }

    // 开始物理修饰键触摸
    @objc private func moddown(_ sender: UIButton) {
        guard
            let button = sender as? BoardButton,
            let spec = button.spec,
            let modifier = spec.kind.modifierKey,
            let key = spec.kind.hidKey
        else { return }
        guard modifiers.press(modifier) else { return }
        state.shftuse()
        guard HIDBridge.shared.keyDown(key) else {
            modifiers.release(modifier)
            updmods()
            return
        }
        updmods()
    }

    // 完成修饰键单击
    @objc private func modtap(_ sender: UIButton) {
        guard
            let spec = (sender as? BoardButton)?.spec,
            let modifier = spec.kind.modifierKey,
            let key = spec.kind.hidKey
        else { return }
        guard modifiers.tap(modifier) else { return }
        if !HIDBridge.shared.keyUp(key) {
            rsthid()
            return
        }
        updmods()
    }

    // 取消修饰键触摸
    @objc private func modcncl(_ sender: UIButton) {
        guard
            let spec = (sender as? BoardButton)?.spec,
            let modifier = spec.kind.modifierKey,
            let key = spec.kind.hidKey
        else { return }
        guard modifiers.release(modifier) else { return }
        if !HIDBridge.shared.keyUp(key) {
            rsthid()
            return
        }
        updmods()
    }

    // 刷新全部修饰键活动外观
    private func updmods() {
        for button in buttons {
            guard
                let spec = button.spec,
                let modifier = spec.kind.modifierKey,
                var config = button.configuration
            else { continue }
            let active = modifiers.contains(modifier)
            config.baseForegroundColor = active ? .systemBackground : .label
            config.baseBackgroundColor = active
                ? theme.primary.uiclr
                : theme.accent.uiclr.withAlphaComponent(0.24)
            button.configuration = config
            button.accessibilityValue = active ? "已按下" : nil
            if active {
                button.accessibilityTraits.insert(.selected)
            } else {
                button.accessibilityTraits.remove(.selected)
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
        guard let button = sender.view as? BoardButton else { return }
        state.shftuse()
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
        for button in buttons {
            button.hidactive = false
            button.fnupper = nil
        }
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
        bldkbd()
    }

    // 开始 Shift 触摸
    @objc private func shftdown(_ sender: UIButton) {
        guard
            let spec = (sender as? BoardButton)?.spec,
            let shift = spec.shiftKey,
            let key = spec.hidKey
        else { return }
        state.shftdown(shift)
        HIDBridge.shared.keyDown(key)
        rfrshft()
    }

    // 完成 Shift 触摸
    @objc private func shftup(_ sender: UIButton) {
        guard
            let spec = (sender as? BoardButton)?.spec,
            let shift = spec.shiftKey,
            let key = spec.hidKey
        else { return }
        HIDBridge.shared.keyUp(key)
        state.shftup(shift)
        rfrshft()
    }

    // 取消 Shift 触摸
    @objc private func shftcncl(_ sender: UIButton) {
        guard
            let spec = (sender as? BoardButton)?.spec,
            let shift = spec.shiftKey,
            let key = spec.hidKey
        else { return }
        HIDBridge.shared.keyUp(key)
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
                config.baseForegroundColor = state.shifted ? .systemBackground : .label
                config.baseBackgroundColor = state.shifted
                    ? theme.primary.uiclr
                    : theme.accent.uiclr.withAlphaComponent(0.24)
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
        guard let button = sender.view as? BoardButton, let spec = button.spec else { return }
        let distance = max(sender.translation(in: button).y, 0)

        switch sender.state {
        case .began:
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
    private func begdrag(_ button: BoardButton, spec: KeySpec) {
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
    private func upddrag(_ button: BoardButton, spec: KeySpec, distance: CGFloat) {
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
    private func rstdrag(_ button: BoardButton, spec: KeySpec, animated: Bool) {
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
    private func mkdraglbl(_ text: String, size: CGFloat, button: BoardButton) -> UILabel {
        let label = UILabel(frame: button.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.font = .systemFont(ofSize: size, weight: .medium)
        label.text = text
        label.textAlignment = .center
        label.textColor = .label
        label.isUserInteractionEnabled = false
        label.isAccessibilityElement = false
        return label
    }

    // 创建不可交互图标视图
    private func mkdragimg(_ name: String, button: BoardButton) -> UIImageView {
        let image = UIImageView(frame: button.bounds)
        image.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        image.image = UIImage(systemName: name)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        )
        image.contentMode = .center
        image.tintColor = .label
        image.isUserInteractionEnabled = false
        image.isAccessibilityElement = false
        return image
    }

    // 移除下拖临时图例
    private func clrdrag(_ button: BoardButton) {
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
