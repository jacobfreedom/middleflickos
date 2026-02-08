import Cocoa

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private var statusLineItem: NSMenuItem?
    private var trusted = false
    private var launchAtLoginEnabled = false

    var onOpenSettings: (() -> Void)?
    var onToggleLaunchAtLogin: (() -> Void)?
    var onOpenAbout: (() -> Void)?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureIcon()
        rebuildMenu()
    }

    func update(trusted: Bool, launchAtLoginEnabled: Bool) {
        self.trusted = trusted
        self.launchAtLoginEnabled = launchAtLoginEnabled
        rebuildMenu()
    }

    func showError(_ message: String) {
        if statusLineItem == nil {
            rebuildMenu()
        }
        statusLineItem?.title = message
    }

    private func configureIcon() {
        if let button = statusItem.button {
            let dimension = NSStatusBar.system.thickness
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true
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

    private func rebuildMenu() {
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
            menu.addItem(settingsItem)
            menu.addItem(NSMenuItem.separator())
        }

        if #available(macOS 13.0, *) {
            let launchAtLoginItem = NSMenuItem(
                title: "Launch at Login",
                action: #selector(toggleLaunchAtLogin),
                keyEquivalent: ""
            )
            launchAtLoginItem.target = self
            launchAtLoginItem.state = launchAtLoginEnabled ? .on : .off
            menu.addItem(launchAtLoginItem)
        }

        let aboutItem = NSMenuItem(
            title: "About MiddleFlickOS…",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem(
                title: "Quit",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        statusItem.menu = menu
    }

    @objc private func openSystemSettings() {
        onOpenSettings?()
    }

    @objc private func toggleLaunchAtLogin() {
        onToggleLaunchAtLogin?()
    }

    @objc private func openAbout() {
        onOpenAbout?()
    }
}
