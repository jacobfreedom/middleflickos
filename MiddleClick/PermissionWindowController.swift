import Cocoa

final class PermissionWindowController: NSObject {
    private var window: NSWindow?

    var onOpenSettings: (() -> Void)?
    var onCheckAgain: (() -> Void)?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 190),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MiddleClick Setup"
        window.isReleasedWhenClosed = false
        window.level = .normal

        guard let contentView = window.contentView else { return }

        let messageField = NSTextField(wrappingLabelWithString:
            "MiddleClick needs Accessibility permission to convert " +
            "Fn+Click to Middle Click.\n\n" +
            "Please enable it in System Settings → Privacy & Security → " +
            "Accessibility. This app will activate automatically once " +
            "permission is granted."
        )
        messageField.isEditable = false
        messageField.isSelectable = false
        messageField.font = .systemFont(ofSize: 13)

        let openButton = NSButton(
            title: "Open System Settings",
            target: self,
            action: #selector(openSettingsPressed)
        )
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"

        let checkButton = NSButton(
            title: "Check Again",
            target: self,
            action: #selector(checkAgainPressed)
        )
        checkButton.bezelStyle = .rounded

        for view in [messageField, openButton, checkButton] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }

        NSLayoutConstraint.activate([
            messageField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            messageField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            messageField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            openButton.topAnchor.constraint(equalTo: messageField.bottomAnchor, constant: 20),
            openButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            checkButton.centerYAnchor.constraint(equalTo: openButton.centerYAnchor),
            checkButton.trailingAnchor.constraint(equalTo: openButton.leadingAnchor, constant: -8),

            openButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
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

    @objc private func checkAgainPressed() {
        onCheckAgain?()
    }
}
