import Cocoa

final class PermissionWindowController: NSObject {
    private var window: NSWindow?

    var onOpenSettings: (() -> Void)?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 220),
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
            "MiddleFlickOS needs Accessibility to convert Fn+Click into Middle Click.\n\n" +
            "1) Click Open System Settings.\n" +
            "2) Enable MiddleFlickOS in Privacy & Security > Accessibility.\n\n" +
            "This window closes automatically once permission is granted."
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

        let buttonStack = NSStackView(views: [openButton])
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
}
