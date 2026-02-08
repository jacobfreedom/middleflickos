import Cocoa
import ApplicationServices

final class AccessibilityController {
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
        let trusted = checkTrusted()
        if trusted != isTrusted {
            isTrusted = trusted
            onTrustedChange?(trusted)
        }
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

    private func checkTrusted() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }
}
