import Cocoa

final class PermissionWindowController: NSObject {
    private var window: NSWindow?

    var onOpenSettings: (() -> Void)?
    var onAddToAccessibility: (() -> Void)?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MiddleFlickOS Setup"
        window.isReleasedWhenClosed = false
        window.level = .normal

        guard let contentView = window.contentView else { return }

        let iconView = NSImageView()
        if let icon = NSImage(named: "AppIcon") {
            iconView.image = icon
        } else {
            iconView.image = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: "MiddleFlickOS")
        }
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48)
        ])

        let titleField = NSTextField(labelWithString: "Enable Accessibility")
        titleField.font = .boldSystemFont(ofSize: 15)

        let messageField = NSTextField(wrappingLabelWithString:
            "MiddleFlickOS is a menu bar app (top-right of your screen). " +
            "It needs Accessibility permission to convert Fn+Click " +
            "into a Middle Click.\n\n" +
            "Open System Settings → Privacy & Security → Accessibility, " +
            "then enable MiddleFlickOS. If it doesn't appear, click " +
            "“Add to Accessibility…” to manually select /Applications/MiddleFlickOS.app.\n\n" +
            "This app will activate automatically once permission is granted."
        )
        messageField.font = .systemFont(ofSize: 13)

        let headerStack = NSStackView(views: [iconView, titleField])
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 12

        let openButton = NSButton(
            title: "Open System Settings",
            target: self,
            action: #selector(openSettingsPressed)
        )
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"

        let addButton = NSButton(
            title: "Add to Accessibility…",
            target: self,
            action: #selector(addToAccessibilityPressed)
        )
        addButton.bezelStyle = .rounded

        let buttonStack = NSStackView(views: [addButton, openButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.spacing = 8
        buttonStack.distribution = .fill

        let contentStack = NSStackView(views: [headerStack, messageField, buttonStack])
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        for view in [headerStack, messageField, buttonStack] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            buttonStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor)
        ])

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)

        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }

    @objc private func openSettingsPressed() {
        onOpenSettings?()
    }

    @objc private func addToAccessibilityPressed() {
        onAddToAccessibility?()
    }
}
