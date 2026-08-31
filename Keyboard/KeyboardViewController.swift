// 显示基础文字输入键盘
import MagicBoardShared
import UIKit

// 标识按键行为
private enum KeyKind: Int {
    case text
    case shift
    case caps
    case delete
    case enter
    case space
    case next
    case letters
    case numbers
    case symbols
    case placeholder
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

    // 创建按键描述
    init(
        _ title: String = "",
        image: String? = nil,
        output: String = "",
        alternate: String? = nil,
        letter: Bool = false,
        kind: KeyKind = .text,
        weight: CGFloat = 1,
        enabled: Bool = true
    ) {
        self.title = title
        self.image = image
        self.output = output
        self.alternate = alternate
        self.letter = letter
        self.kind = kind
        self.weight = weight
        self.enabled = enabled
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

    // 生成当前键盘页面
    private func bldkbd() {
        for item in rows.arrangedSubviews {
            rows.removeArrangedSubview(item)
            item.removeFromSuperview()
        }

        rows.addArrangedSubview(mkrow(fnrow()))
        let pageRows: [[KeySpec]]
        switch state.page {
        case .letters:
            pageRows = ltrrows()
        case .numbers:
            pageRows = numrows()
        case .symbols:
            pageRows = symrows()
        }
        for specs in pageRows {
            rows.addArrangedSubview(mkrow(specs))
        }
        rows.addArrangedSubview(mkrow(btmrow()))
    }

    // 创建功能键占位行
    private func fnrow() -> [KeySpec] {
        [
            ph("esc", weight: 1.25),
            ph(image: "sun.min"),
            ph(image: "sun.max"),
            ph(image: "rectangle.3.group"),
            ph(image: "magnifyingglass"),
            ph(image: "mic"),
            ph(image: "moon"),
            ph(image: "backward.fill"),
            ph(image: "playpause.fill"),
            ph(image: "forward.fill"),
            ph(image: "speaker.slash.fill"),
            ph(image: "speaker.wave.1.fill"),
            ph(image: "speaker.wave.3.fill"),
            ph(image: "lock", weight: 1.25),
        ]
    }

    // 创建字母页面行
    private func ltrrows() -> [[KeySpec]] {
        [
            [
                txt("`", alternate: "~"), txt("1", alternate: "!"), txt("2", alternate: "@"),
                txt("3", alternate: "#"), txt("4", alternate: "$"), txt("5", alternate: "%"),
                txt("6", alternate: "^"), txt("7", alternate: "&"), txt("8", alternate: "*"),
                txt("9", alternate: "("), txt("0", alternate: ")"), txt("-", alternate: "_"),
                txt("=", alternate: "+"), ctl(image: "delete.left", kind: .delete, weight: 1.7),
            ],
            [
                ph("tab", weight: 1.5), ltr("Q"), ltr("W"), ltr("E"), ltr("R"), ltr("T"),
                ltr("Y"), ltr("U"), ltr("I"), ltr("O"), ltr("P"),
                txt("[", alternate: "{"), txt("]", alternate: "}"), txt("\\", alternate: "|", weight: 1.5),
            ],
            [
                ctl(image: state.capsLocked ? "capslock.fill" : "capslock", kind: .caps, weight: 1.8),
                ltr("A"), ltr("S"), ltr("D"), ltr("F"), ltr("G"), ltr("H"), ltr("J"), ltr("K"), ltr("L"),
                txt(";", alternate: ":"), txt("'", alternate: "\""),
                ctl(image: "return", kind: .enter, weight: 1.9),
            ],
            [
                ctl(image: state.shifted ? "shift.fill" : "shift", kind: .shift, weight: 2.25),
                ltr("Z"), ltr("X"), ltr("C"), ltr("V"), ltr("B"), ltr("N"), ltr("M"),
                txt(",", alternate: "<"), txt(".", alternate: ">"), txt("/", alternate: "?"),
                ctl(image: state.shifted ? "shift.fill" : "shift", kind: .shift, weight: 2.25),
            ],
        ]
    }

    // 创建数字页面行
    private func numrows() -> [[KeySpec]] {
        [
            txtrow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]) + [
                ctl(image: "delete.left", kind: .delete, weight: 1.7),
            ],
            txtrow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]),
            txtrow([".", ",", "?", "!", "'", "[", "]", "{", "}"]) + [
                ctl(image: "return", kind: .enter, weight: 1.7),
            ],
            txtrow(["+", "=", "*", "%", "#", "<", ">", "_", "\\", "|"]),
        ]
    }

    // 创建符号页面行
    private func symrows() -> [[KeySpec]] {
        [
            txtrow(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]) + [
                ctl(image: "delete.left", kind: .delete, weight: 1.7),
            ],
            txtrow(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"]),
            txtrow([".", ",", "?", "!", "'", "\"", "`", ";", ":"]) + [
                ctl(image: "return", kind: .enter, weight: 1.7),
            ],
            txtrow(["©", "®", "™", "✓", "§", "±", "÷", "×", "°", "…"]),
        ]
    }

    // 创建底部控制行
    private func btmrow() -> [KeySpec] {
        let lead: KeySpec
        let tail: KeySpec
        switch state.page {
        case .letters:
            lead = ctl("123", kind: .numbers, weight: 1.25)
            tail = ph(image: "arrow.left.and.right", weight: 1.25)
        case .numbers:
            lead = ctl("#+=", kind: .symbols, weight: 1.25)
            tail = ctl("ABC", kind: .letters, weight: 1.25)
        case .symbols:
            lead = ctl("123", kind: .numbers, weight: 1.25)
            tail = ctl("ABC", kind: .letters, weight: 1.25)
        }

        return [
            lead,
            ctl(image: "globe", kind: .next, weight: 1.05),
            ph("control", weight: 1.15),
            ph("option", weight: 1.15),
            ph("command", weight: 1.25),
            ctl("space", kind: .space, weight: 5),
            ph("command", weight: 1.25),
            ph("option", weight: 1.15),
            tail,
        ]
    }

    // 创建字母按键描述
    private func ltr(_ title: String) -> KeySpec {
        KeySpec(title, output: title.lowercased(), letter: true)
    }

    // 创建文字按键描述
    private func txt(_ title: String, alternate: String? = nil, weight: CGFloat = 1) -> KeySpec {
        KeySpec(title, output: title, alternate: alternate, weight: weight)
    }

    // 创建文字按键数组
    private func txtrow(_ titles: [String]) -> [KeySpec] {
        titles.map { txt($0) }
    }

    // 创建控制按键描述
    private func ctl(
        _ title: String = "",
        image: String? = nil,
        kind: KeyKind,
        weight: CGFloat = 1
    ) -> KeySpec {
        KeySpec(title, image: image, kind: kind, weight: weight)
    }

    // 创建任务三占位描述
    private func ph(_ title: String = "", image: String? = nil, weight: CGFloat = 1) -> KeySpec {
        KeySpec(title, image: image, kind: .placeholder, weight: weight, enabled: false)
    }

    // 创建自适应按键行
    private func mkrow(_ specs: [KeySpec]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fill
        row.spacing = 5

        var base: (button: UIButton, weight: CGFloat)?
        for spec in specs {
            let button = mkkey(spec)
            row.addArrangedSubview(button)
            if let base {
                button.widthAnchor.constraint(
                    equalTo: base.button.widthAnchor,
                    multiplier: spec.weight / base.weight
                ).isActive = true
            } else {
                base = (button, spec.weight)
            }
        }
        return row
    }

    // 创建单个键帽
    private func mkkey(_ spec: KeySpec) -> BoardButton {
        let button = BoardButton(type: .system)
        button.spec = spec
        button.isEnabled = spec.enabled
        button.accessibilityLabel = aclabel(spec)
        if spec.kind == .placeholder {
            button.accessibilityHint = "任务 3 实现"
        }

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.title = spec.title.isEmpty ? nil : spec.title
        config.image = spec.image.flatMap(UIImage.init(systemName:))
        config.imagePlacement = .leading
        config.imagePadding = 3
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .medium)
            return outgoing
        }

        let selected = (spec.kind == .shift && state.shifted) || (spec.kind == .caps && state.capsLocked)
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

        if spec.kind == .next {
            button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        } else if spec.kind != .placeholder {
            button.addTarget(self, action: #selector(prskey(_:)), for: .touchUpInside)
        }
        return button
    }

    // 生成按键辅助标签
    private func aclabel(_ spec: KeySpec) -> String {
        switch spec.kind {
        case .shift: "Shift"
        case .caps: "Caps Lock"
        case .delete: "删除"
        case .enter: "换行"
        case .space: "空格"
        case .next: "下一个键盘"
        case .letters: "字母键盘"
        case .numbers: "数字键盘"
        case .symbols: "符号键盘"
        case .placeholder: spec.title.isEmpty ? "任务 3 功能键" : "\(spec.title)，任务 3 功能键"
        case .text: spec.title
        }
    }

    // 处理全部可用按键
    @objc private func prskey(_ sender: UIButton) {
        guard let spec = (sender as? BoardButton)?.spec else { return }
        switch spec.kind {
        case .text:
            let hadShift = state.shifted
            let output = state.emit(spec.output, alternate: spec.alternate, letter: spec.letter)
            textDocumentProxy.insertText(output)
            if hadShift { bldkbd() }
        case .shift:
            state.tglshft()
            bldkbd()
        case .caps:
            state.tglcaps()
            bldkbd()
        case .delete:
            textDocumentProxy.deleteBackward()
        case .enter:
            textDocumentProxy.insertText("\n")
        case .space:
            textDocumentProxy.insertText(" ")
        case .letters:
            state.setpage(.letters)
            bldkbd()
        case .numbers:
            state.setpage(.numbers)
            bldkbd()
        case .symbols:
            state.setpage(.symbols)
            bldkbd()
        case .next, .placeholder:
            break
        }
    }
}

// 转换共享主题颜色
private extension ThemeColor {
    var uiclr: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
