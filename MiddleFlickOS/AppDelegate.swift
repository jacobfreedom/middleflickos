import Cocoa
import ApplicationServices
import ServiceManagement
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {

    private let statusBar = StatusBarController()
    private let accessibility = AccessibilityController()
    private let permissionWindow = PermissionWindowController()
    private let eventTap = EventTapManager()

    private var isActivated = false

    private static let loginItemPromptKey = "loginItemPromptShown"
    private static let websiteURL = "https://middleflickos.vercel.app/"

    func applicationDidFinishLaunching(_ notification: Notification) {
        wireControllers()

        accessibility.start()
        refreshStatusMenu()

        if accessibility.isTrusted {
            activateIfNeeded()
        } else {
            permissionWindow.show()
        }
    }

    private func wireControllers() {
        statusBar.onOpenSettings = { [weak self] in
            self?.openAccessibilitySettings()
        }

        statusBar.onToggleLaunchAtLogin = { [weak self] in
            self?.toggleLaunchAtLogin()
        }

        statusBar.onOpenAbout = { [weak self] in
            self?.showAboutPanel()
        }

        permissionWindow.onOpenSettings = { [weak self] in
            self?.openAccessibilitySettings()
        }

        permissionWindow.onAddToAccessibility = { [weak self] in
            self?.showAddToAccessibilityPanel()
        }

        accessibility.onTrustedChange = { [weak self] trusted in
            self?.handleTrustChange(isTrusted: trusted)
        }
    }

    private func handleTrustChange(isTrusted: Bool) {
        refreshStatusMenu(trustedOverride: isTrusted)

        if isTrusted {
            permissionWindow.close()
            activateIfNeeded()
        } else {
            eventTap.stop()
            isActivated = false
            permissionWindow.show()
        }
    }

    private func openAccessibilitySettings() {
        accessibility.openAccessibilitySettings()
    }

    private func showAddToAccessibilityPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.nameFieldStringValue = "MiddleFlickOS.app"

        panel.begin { [weak self] response in
            guard response == .OK else { return }
            self?.accessibility.refreshTrust()
        }
    }

    private func activateIfNeeded() {
        guard !isActivated else { return }
        isActivated = true

        if !eventTap.start() {
            statusBar.showError("Error: could not create event tap")
            return
        }

        promptLoginItemIfNeeded()
    }

    private func refreshStatusMenu(trustedOverride: Bool? = nil) {
        let trusted = trustedOverride ?? accessibility.isTrusted
        statusBar.update(trusted: trusted, launchAtLoginEnabled: launchAtLoginEnabled())
    }

    private func openWebsite() {
        guard let url = URL(string: Self.websiteURL) else { return }
        NSWorkspace.shared.open(url)
    }

    private func showAboutPanel() {
        let alert = NSAlert()
        alert.messageText = "About MiddleFlickOS"
        alert.informativeText =
            "MiddleFlickOS is a lean menu bar utility for Fn+Click to Middle Click.\n\n" +
            "No internet connection. No telemetry.\n\n" +
            "To check for updates, visit the official site."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Visit Website")
        alert.addButton(withTitle: "OK")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openWebsite()
        }
    }

    private func launchAtLoginEnabled() -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    @available(macOS 13.0, *)
    private func setLaunchAtLogin(enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    private func toggleLaunchAtLogin() {
        guard #available(macOS 13.0, *) else { return }

        let shouldEnable = !launchAtLoginEnabled()
        do {
            try setLaunchAtLogin(enabled: shouldEnable)
            UserDefaults.standard.set(true, forKey: Self.loginItemPromptKey)
        } catch {
            showLoginItemError(error)
        }
        refreshStatusMenu()
    }

    private func showLoginItemError(_ error: Error) {
        let errAlert = NSAlert()
        errAlert.messageText = "Could Not Update Launch at Login"
        errAlert.informativeText = error.localizedDescription
        errAlert.alertStyle = .warning
        errAlert.addButton(withTitle: "OK")
        errAlert.runModal()
    }

    // MARK: - Login Item Prompt

    private func promptLoginItemIfNeeded() {
        if UserDefaults.standard.bool(forKey: Self.loginItemPromptKey) {
            return
        }

        guard #available(macOS 13.0, *) else { return }

        if launchAtLoginEnabled() {
            UserDefaults.standard.set(true, forKey: Self.loginItemPromptKey)
            refreshStatusMenu()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showLoginItemAlert()
        }
    }

    @available(macOS 13.0, *)
    private func showLoginItemAlert() {
        let alert = NSAlert()
        alert.messageText = "Launch at Login (Recommended)"
        alert.informativeText =
            "MiddleFlickOS works best when it starts automatically and stays in your menu bar. Enable launch at login?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Enable")
        alert.addButton(withTitle: "Not Now")

        let response = alert.runModal()

        UserDefaults.standard.set(true, forKey: Self.loginItemPromptKey)

        if response == .alertFirstButtonReturn {
            do {
                try setLaunchAtLogin(enabled: true)
            } catch {
                showLoginItemError(error)
            }
        }

        refreshStatusMenu()
    }
}
