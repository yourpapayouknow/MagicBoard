// 显示可输入文字的测试键盘
import MagicBoardShared
import UIKit

// 管理键盘扩展界面
final class KeyboardViewController: UIInputViewController {
    private let rows = UIStackView()
    private let status = UILabel()
    private var theme = SharedConfig.ldthm()
    private var height: NSLayoutConstraint?

    // 构建测试键盘
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)

        rows.axis = .vertical
        rows.alignment = .fill
        rows.distribution = .fillEqually
        rows.spacing = 8
        rows.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(rows)

        height = view.heightAnchor.constraint(equalToConstant: 310)
        height?.priority = .init(999)
        height?.isActive = true

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rows.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 10),
            rows.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -10),
            rows.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 10),
            rows.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -10),
        ])

        bldkbd()
    }

    // 刷新主题与权限状态
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theme = SharedConfig.ldthm()
        bldkbd()
    }

    // 生成全部键盘行
    private func bldkbd() {
        rows.arrangedSubviews.forEach { item in
            rows.removeArrangedSubview(item)
            item.removeFromSuperview()
        }

        status.text = hasFullAccess ? "MagicBoard 测试键盘 · 完全访问已开启" : "MagicBoard 测试键盘 · 请开启完全访问"
        status.font = .preferredFont(forTextStyle: .footnote)
        status.textColor = .secondaryLabel
        status.textAlignment = .center
        rows.addArrangedSubview(status)

        rows.addArrangedSubview(mkrow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]))
        rows.addArrangedSubview(mkrow(["A", "S", "D", "F", "G", "H", "J", "K", "L"]))
        rows.addArrangedSubview(mkrow(["Z", "X", "C", "V", "B", "N", "M"]))
        rows.addArrangedSubview(mkctl())
    }

    // 创建文字按键行
    private func mkrow(_ values: [String]) -> UIStackView {
        let row = mkstack()
        for value in values {
            row.addArrangedSubview(mktext(value))
        }
        return row
    }

    // 创建控制按键行
    private func mkctl() -> UIStackView {
        let row = mkstack()
        row.addArrangedSubview(mkctrl(
            "globe",
            label: "下一个键盘",
            action: #selector(handleInputModeList(from:with:)),
            events: .allTouchEvents
        ))
        row.addArrangedSubview(mkctrl("delete.left", label: "删除", action: #selector(deltxt)))
        row.addArrangedSubview(mktext("空格", value: " "))
        row.addArrangedSubview(mkctrl("return", label: "换行", action: #selector(entertxt)))
        return row
    }

    // 创建横向按键容器
    private func mkstack() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 6
        return row
    }

    // 创建文字按键
    private func mktext(_ title: String, value: String? = nil) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.baseForegroundColor = .label
        config.baseBackgroundColor = theme.primary.uiclr.withAlphaComponent(0.22)
        config.title = title
        button.configuration = config
        button.accessibilityValue = value ?? title.lowercased()
        button.addTarget(self, action: #selector(puttxt(_:)), for: .touchUpInside)
        return button
    }

    // 创建控制按键
    private func mkctrl(
        _ image: String,
        label: String,
        action: Selector,
        events: UIControl.Event = .touchUpInside
    ) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.baseForegroundColor = .label
        config.baseBackgroundColor = theme.accent.uiclr.withAlphaComponent(0.26)
        config.image = UIImage(systemName: image)
        button.configuration = config
        button.accessibilityLabel = label
        button.addTarget(self, action: action, for: events)
        return button
    }

    // 输入按键文字
    @objc private func puttxt(_ sender: UIButton) {
        guard let value = sender.accessibilityValue else { return }
        textDocumentProxy.insertText(value)
    }

    // 删除光标前文字
    @objc private func deltxt() {
        textDocumentProxy.deleteBackward()
    }

    // 输入换行符
    @objc private func entertxt() {
        textDocumentProxy.insertText("\n")
    }

}

// 转换共享主题颜色
private extension ThemeColor {
    var uiclr: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
