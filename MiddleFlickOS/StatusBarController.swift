import Cocoa

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private var statusLineItem: NSMenuItem?
    private var openSettingsItem: NSMenuItem?

    var onOpenSettings: (() -> Void)?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureIcon()
        rebuildMenu(trusted: false)
    }

    func update(trusted: Bool) {
        rebuildMenu(trusted: trusted)
    }

    func showError(_ message: String) {
        if statusLineItem == nil {
            rebuildMenu(trusted: false)
        }
        statusLineItem?.title = message
    }

    private func configureIcon() {
        if let button = statusItem.button {
            let dimension = NSStatusBar.system.thickness
            if let image = NSImage(named: "AppIcon") {
                image.isTemplate = false
                image.size = NSSize(width: dimension, height: dimension)
                button.image = image
                button.image?.isTemplate = true
            } else if let image = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: "MiddleFlickOS") {
                image.isTemplate = true
                image.size = NSSize(width: dimension, height: dimension)
                button.image = image
                button.image?.isTemplate = true
            } else {
                button.title = "MC"
            }
        }
    }

    private func rebuildMenu(trusted: Bool) {
        let menu = NSMenu()

        let status = NSMenuItem(
            title: trusted ? "Running" : "Waiting for permission…",
            action: nil,
            keyEquivalent: ""
        )
        statusLineItem = status
        menu.addItem(status)
        menu.addItem(NSMenuItem.separator())

        if !trusted {
            let settingsItem = NSMenuItem(
                title: "Open System Settings",
                action: #selector(openSystemSettings),
                keyEquivalent: ""
            )
            settingsItem.target = self
            openSettingsItem = settingsItem
            menu.addItem(settingsItem)
            menu.addItem(NSMenuItem.separator())
        } else {
            openSettingsItem = nil
        }

        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    @objc private func openSystemSettings() {
        onOpenSettings?()
    }
}
