import Cocoa
import ApplicationServices
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {

    private let statusBar = StatusBarController()
    private let accessibility = AccessibilityController()
    private let permissionWindow = PermissionWindowController()
    private let eventTap = EventTapManager()

    private var isActivated = false

    private static let loginItemPromptKey = "loginItemPromptShown"

    func applicationDidFinishLaunching(_ notification: Notification) {
        wireControllers()

        accessibility.start()

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

        permissionWindow.onOpenSettings = { [weak self] in
            self?.openAccessibilitySettings()
        }

        permissionWindow.onCheckAgain = { [weak self] in
            self?.accessibility.refreshTrust()
        }

        accessibility.onTrustedChange = { [weak self] trusted in
            self?.handleTrustChange(isTrusted: trusted)
        }
    }

    private func handleTrustChange(isTrusted: Bool) {
        statusBar.update(trusted: isTrusted)

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
        accessibility.requestPermissionOnce()
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

    // MARK: - Login Item Prompt

    private func promptLoginItemIfNeeded() {
        if UserDefaults.standard.bool(forKey: Self.loginItemPromptKey) {
            return
        }

        guard #available(macOS 13.0, *) else { return }

        if SMAppService.mainApp.status == .enabled {
            UserDefaults.standard.set(true, forKey: Self.loginItemPromptKey)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showLoginItemAlert()
        }
    }

    @available(macOS 13.0, *)
    private func showLoginItemAlert() {
        let alert = NSAlert()
        alert.messageText = "Start at Login?"
        alert.informativeText =
            "Would you like MiddleClick to launch automatically when you log in?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        let response = alert.runModal()

        UserDefaults.standard.set(true, forKey: Self.loginItemPromptKey)

        if response == .alertFirstButtonReturn {
            do {
                try SMAppService.mainApp.register()
            } catch {
                let errAlert = NSAlert()
                errAlert.messageText = "Could Not Enable Login Item"
                errAlert.informativeText = error.localizedDescription
                errAlert.alertStyle = .warning
                errAlert.addButton(withTitle: "OK")
                errAlert.runModal()
            }
        }
    }
}
