// 显示基础文字输入键盘
import MagicBoardShared
import UIKit

// 标识按键行为
private enum KeyKind: Int {
    case text
    case shift
    case language
    case delete
    case enter
    case space
    case next
    case dismiss
    case placeholder
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
        stackIcon: Bool = false
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
    }
}

// 保存按键描述
private final class BoardButton: UIButton {
    var spec: KeySpec?
}

// 管理键盘扩展界面
final class KeyboardViewController: UIInputViewController {
    private let rows = UIStackView()
    private var theme = SharedConfig.ldthm()
    private var state = InputState()
    private var height: NSLayoutConstraint?
    private var buttons: [BoardButton] = []
    // 仅由主 RunLoop 触摸生命周期访问
    nonisolated(unsafe) private var deltimer: Timer?

    // 清理扩展计时器
    deinit {
        deltimer?.invalidate()
    }

    // 构建键盘容器
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)

        rows.axis = .vertical
        rows.alignment = .fill
        rows.distribution = .fillEqually
        rows.spacing = 6
        rows.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(rows)

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
        stopdel()
        state.shftcncl()
    }

    // 生成固定键盘布局
    private func bldkbd() {
        stopdel()
        state.shftcncl()
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

    // 创建 Mac 功能键占位行
    private func fnrow() -> [KeySpec] {
        [
            ph("Esc", weight: 1.5, align: .leading, fontSize: 17),
            ph("F1", image: "sun.min", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F2", image: "sun.max", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F3", image: "rectangle.3.group", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F4", image: "magnifyingglass", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F5", image: "mic", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F6", image: "moon", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F7", image: "backward", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F8", image: "playpause", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F9", image: "forward", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F10", image: "speaker.slash", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F11", image: "speaker.wave.1", align: .bottom, fontSize: 13, stackIcon: true),
            ph("F12", image: "speaker.wave.3", align: .bottom, fontSize: 13, stackIcon: true),
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
                ph("tab", weight: 1.5, align: .leading, fontSize: 17), ltr("Q"), ltr("W"), ltr("E"), ltr("R"), ltr("T"),
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
                ctl("shift", kind: .shift, weight: 2.25, align: .leading),
                ltr("Z"), ltr("X"), ltr("C"), ltr("V"), ltr("B"), ltr("N"), ltr("M"),
                txt(",", alternate: "<", zhBase: "，", zhAlt: "《"),
                txt(".", alternate: ">", zhBase: "。", zhAlt: "》"), txt("/", alternate: "?"),
                ctl("shift", kind: .shift, weight: 2.25, align: .trailing),
            ],
        ]
    }

    // 创建底部控制行
    private func btmrow() -> [KeySpec] {
        [
            ctl(image: "globe", kind: .next, weight: 1.05, align: .leading),
            ph("Ctrl", weight: 1.15, align: .leading, fontSize: 17),
            ph(image: "option", weight: 1.15, align: .leading),
            ph(image: "command", weight: 1.25, align: .leading),
            ctl("space", kind: .space, weight: 5),
            ph(image: "command", weight: 1.25, align: .trailing),
            ph(image: "option", weight: 1.15, align: .trailing),
            ph(image: "arrow.left", weight: 0.75),
            ph(image: "arrow.up.arrow.down", weight: 0.75),
            ph(image: "arrow.right", weight: 0.75),
        ]
    }

    // 创建字母按键描述
    private func ltr(_ title: String) -> KeySpec {
        let label = state.uppercase ? title.uppercased() : title.lowercased()
        return KeySpec(label, output: title.lowercased(), letter: true, fontSize: 27)
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
        return KeySpec(label, output: output, alternate: alternate, weight: weight, fontSize: size)
    }

    // 创建控制按键描述
    private func ctl(
        _ title: String = "",
        image: String? = nil,
        kind: KeyKind,
        weight: CGFloat = 1,
        align: KeyAlign = .center,
        fontSize: CGFloat = 17
    ) -> KeySpec {
        KeySpec(title, image: image, kind: kind, weight: weight, align: align, fontSize: fontSize)
    }

    // 创建任务三占位描述
    private func ph(
        _ title: String = "",
        image: String? = nil,
        weight: CGFloat = 1,
        align: KeyAlign = .center,
        fontSize: CGFloat = 11,
        stackIcon: Bool = false
    ) -> KeySpec {
        KeySpec(
            title,
            image: image,
            kind: .placeholder,
            weight: weight,
            enabled: false,
            align: align,
            fontSize: fontSize,
            stackIcon: stackIcon
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
        pair.addArrangedSubview(mkkey(ph(image: "arrow.up")))
        pair.addArrangedSubview(mkkey(ph(image: "arrow.down")))
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

        let selected = (spec.kind == .shift && state.shifted)
            || (spec.kind == .language && state.capsLocked)
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

        if spec.kind == .next {
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

    // 生成按键辅助标签
    private func aclabel(_ spec: KeySpec) -> String {
        switch spec.kind {
        case .shift: "Shift"
        case .language: "切换输入语言，长按切换 Caps Lock"
        case .delete: "删除"
        case .enter: "换行"
        case .space: "空格"
        case .next: "下一个键盘"
        case .dismiss: "收起键盘"
        case .placeholder: spec.title.isEmpty ? "任务 3 功能键" : "\(spec.title)，任务 3 功能键"
        case .text: spec.title
        }
    }

    // 处理全部可用按键
    @objc private func prskey(_ sender: UIButton) {
        guard let spec = (sender as? BoardButton)?.spec else { return }
        switch spec.kind {
        case .text:
            let output = state.emit(spec.output, alternate: spec.alternate, letter: spec.letter)
            textDocumentProxy.insertText(output)
            rfrshft()
        case .shift:
            state.tglshft()
            rfrshft()
        case .language:
            state.tgllang()
            bldkbd()
        case .delete:
            break
        case .enter:
            textDocumentProxy.insertText("\n")
        case .space:
            textDocumentProxy.insertText(" ")
        case .dismiss:
            dismissKeyboard()
        case .next, .placeholder:
            break
        }
    }

    // 处理语言键长按 Caps Lock
    @objc private func lngcaps(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        state.tglcaps()
        bldkbd()
    }

    // 开始 Shift 触摸
    @objc private func shftdown(_ sender: UIButton) {
        state.shftdown()
        rfrshft()
    }

    // 完成 Shift 触摸
    @objc private func shftup(_ sender: UIButton) {
        state.shftup()
        rfrshft()
    }

    // 取消 Shift 触摸
    @objc private func shftcncl(_ sender: UIButton) {
        state.shftcncl()
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
            } else {
                continue
            }
            button.configuration = config
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
        guard
            sender.state == .ended,
            sender.translation(in: sender.view).y >= 24,
            let button = sender.view as? BoardButton,
            let spec = button.spec
        else { return }

        let output = state.dragout(spec.output, alternate: spec.alternate, letter: spec.letter)
        textDocumentProxy.insertText(output)
        rfrshft()
    }
}

// 转换共享主题颜色
private extension ThemeColor {
    var uiclr: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
