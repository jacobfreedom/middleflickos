import Cocoa
import ApplicationServices

final class AccessibilityController {
    private static let promptKey = "accessibilityPromptShown"
    private static let promptLastDateKey = "accessibilityPromptLastDate"
    private static let promptCooldownSeconds: TimeInterval = 10

    private var pollTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    private(set) var isTrusted: Bool = false
    var onTrustedChange: ((Bool) -> Void)?

    func start() {
        refreshTrust()
        startPolling()
        observeAppState()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil

        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
        observers.removeAll()
    }

    func refreshTrust() {
        let trusted = checkTrusted(prompt: false)
        if trusted != isTrusted {
            isTrusted = trusted
            onTrustedChange?(trusted)
        }
    }

    func requestPermissionOnce() {
        if checkTrusted(prompt: false) {
            UserDefaults.standard.set(true, forKey: Self.promptKey)
            return
        }

        let lastPrompt = UserDefaults.standard.object(forKey: Self.promptLastDateKey) as? Date
        if let lastPrompt, Date().timeIntervalSince(lastPrompt) < Self.promptCooldownSeconds {
            return
        }

        _ = checkTrusted(prompt: true)
        UserDefaults.standard.set(Date(), forKey: Self.promptLastDateKey)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshTrust()
        }
    }

    private func observeAppState() {
        let center = NotificationCenter.default

        observers.append(center.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshTrust()
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshTrust()
        })
    }

    private func checkTrusted(prompt: Bool) -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }
}
