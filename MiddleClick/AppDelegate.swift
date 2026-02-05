import Cocoa
import ApplicationServices
import ServiceManagement

// MARK: - Middle-click session state (accessed from the C callback)

/// Tracks whether we're in an active Fn+Click → middle-click session.
/// When true, ALL subsequent left-mouse events (drag, up) are converted
/// to their middle-mouse equivalents — even if the Fn key is released
/// before the mouse button is released.
private var middleClickSessionActive = false

/// Stored globally so the C callback can re-enable it on timeout.
private var globalEventTap: CFMachPort?

// MARK: - Fn flag constant

private let kCGEventFlagMaskSecondaryFn: UInt64 = 0x00800000  // NX_SECONDARYFNMASK

// MARK: - Menu item tags for dynamic updates

private enum MenuTag: Int {
    case status       = 100
    case openSettings = 200
    case settingsSep  = 300
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var eventTap: CFMachPort?
    private var accessibilityPollTimer: Timer?
    private var permissionWindow: NSWindow?
    private var isActivated = false

    private static let loginItemPromptKey = "loginItemPromptShown"
    private static let accessibilityPromptKey = "accessibilityPromptShown"
    
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "MiddleFlickOS"
    }

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Menu bar is ALWAYS set up first — user can always see the icon and quit
        setupMenuBar()

        // 2. Then check permission and branch
        if isAccessibilityTrusted(prompt: false) {
            onAccessibilityGranted()
        } else {
            showPermissionWindow()
            startAccessibilityPolling()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let image = makeStatusBarIcon()
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.toolTip = appName
            button.setAccessibilityTitle(appName)
        }

        rebuildMenu(trusted: false)
    }

    /// Rebuilds the status-item menu to reflect the current permission state.
    private func rebuildMenu(trusted: Bool) {
        let menu = NSMenu()

        // Status line
        let statusItem = NSMenuItem(
            title: trusted ? "Running" : "Waiting for permission…",
            action: nil,
            keyEquivalent: ""
        )
        statusItem.tag = MenuTag.status.rawValue
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // "Open System Settings" — only when we don't yet have permission
        if !trusted {
            let settingsItem = NSMenuItem(
                title: "Open System Settings",
                action: #selector(openSystemSettings),
                keyEquivalent: ""
            )
            settingsItem.target = self
            settingsItem.tag = MenuTag.openSettings.rawValue
            menu.addItem(settingsItem)

            let sep = NSMenuItem.separator()
            sep.tag = MenuTag.settingsSep.rawValue
            menu.addItem(sep)
        }

        // About — always present
        let aboutItem = NSMenuItem(
            title: "About \(appName)…",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit — always last
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        self.statusItem.menu = menu
    }

    /// Draws a minimalist, geometric middle-finger-style glyph for the menu bar.
    private func makeStatusBarIcon(size: CGFloat = 18) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        defer { img.unlockFocus() }

        let w = size
        let h = size
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: w, height: h)).fill()

        let fg = NSColor.black
        fg.setFill()

        // Proportions
        let palmWidth: CGFloat = 0.62 * w
        let palmHeight: CGFloat = 0.26 * h
        let palmX = (w - palmWidth) / 2
        let palmY: CGFloat = 0.12 * h

        let fingerGap: CGFloat = 0.06 * w
        let fingerWidth: CGFloat = (palmWidth - 2 * fingerGap) / 3
        let leftFingerHeight: CGFloat = 0.38 * h
        let middleFingerHeight: CGFloat = 0.58 * h
        let rightFingerHeight: CGFloat = 0.42 * h
        let fingerBottom = palmY + palmHeight + (0.02 * h)

        let corner: CGFloat = max(1, size * 0.08)

        func roundedRect(_ rect: NSRect, radius: CGFloat) {
            let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
            path.fill()
        }

        // Palm
        roundedRect(NSRect(x: palmX, y: palmY, width: palmWidth, height: palmHeight), radius: corner)

        // Fingers (left, middle, right)
        let leftX = palmX
        let midX = palmX + fingerWidth + fingerGap
        let rightX = palmX + 2 * (fingerWidth + fingerGap)

        roundedRect(NSRect(x: leftX, y: fingerBottom, width: fingerWidth, height: leftFingerHeight), radius: corner)
        roundedRect(NSRect(x: midX, y: fingerBottom, width: fingerWidth, height: middleFingerHeight), radius: corner)
        roundedRect(NSRect(x: rightX, y: fingerBottom, width: fingerWidth, height: rightFingerHeight), radius: corner)

        return img
    }

    @objc private func openSystemSettings() {
        openAccessibilitySettings()
        promptAccessibilityIfNeeded()
    }

    @objc private func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let alert = NSAlert()
        alert.messageText = appName
        let versionLine = version.isEmpty ? "" : "Version \(version)"
        let buildLine = build.isEmpty ? "" : " (\(build))"
        alert.informativeText = versionLine.isEmpty && buildLine.isEmpty ? "" : versionLine + buildLine
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Permission Window (non-modal NSWindow)

    private func showPermissionWindow() {
        // ── Create window first ──

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(appName) Setup"
        window.isReleasedWhenClosed = false
        window.level = .normal

        guard let contentView = window.contentView else { return }

        // ── Build subviews ──

        let messageField = NSTextField(wrappingLabelWithString:
            "\(appName) needs Accessibility permission to convert " +
            "Fn+Click to Middle Click.\n\n" +
            "Click \"Open System Settings\" and enable \(appName) in " +
            "Privacy & Security → Accessibility. This app will activate " +
            "automatically once permission is granted."
        )
        messageField.isEditable = false
        messageField.isSelectable = false
        messageField.font = .systemFont(ofSize: 13)

        let openButton = NSButton(
            title: "Open System Settings",
            target: self,
            action: #selector(openSystemSettings)
        )
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"

        let checkButton = NSButton(
            title: "Check Again",
            target: self,
            action: #selector(checkAgainPressed)
        )
        checkButton.bezelStyle = .rounded

        // ── Add subviews directly to the window's contentView ──

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

            openButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])

        // ── Show window, then open System Settings after a short delay ──

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)

        permissionWindow = window

        // Leave the choice to the user to avoid surprise prompts on launch.
    }

    @objc private func checkAgainPressed() {
        if isAccessibilityTrusted(prompt: false) {
            onAccessibilityGranted()
        }
    }

    // MARK: - Accessibility Polling

    private func startAccessibilityPolling() {
        accessibilityPollTimer = Timer.scheduledTimer(
            withTimeInterval: 1.5,
            repeats: true
        ) { [weak self] _ in
            if self?.isAccessibilityTrusted(prompt: false) == true {
                self?.onAccessibilityGranted()
            }
        }
    }

    /// Called exactly once when accessibility is (or becomes) available.
    private func onAccessibilityGranted() {
        guard !isActivated else { return }
        isActivated = true

        // Stop polling
        accessibilityPollTimer?.invalidate()
        accessibilityPollTimer = nil

        // Close the permission window if it's showing
        permissionWindow?.close()
        permissionWindow = nil

        // Update menu to "Running" state (removes "Open System Settings")
        rebuildMenu(trusted: true)

        // Start intercepting events
        setupEventTap()

        // One-time login-item prompt
        promptLoginItemIfNeeded()
    }

    // MARK: - Accessibility Helpers

    private func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    private func promptAccessibilityIfNeeded() {
        if UserDefaults.standard.bool(forKey: Self.accessibilityPromptKey) {
            return
        }

        guard !isAccessibilityTrusted(prompt: false) else {
            UserDefaults.standard.set(true, forKey: Self.accessibilityPromptKey)
            return
        }

        _ = isAccessibilityTrusted(prompt: true)
        UserDefaults.standard.set(true, forKey: Self.accessibilityPromptKey)
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Event Tap

    // NOTE: The system may log "Unable to obtain a task name port right for pid ..."
    // This is expected — some system processes have restricted task ports.
    // The event tap still works correctly for all user applications.
    private func setupEventTap() {
        let eventMask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue)   |
            (1 << CGEventType.leftMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            // If the tap fails, update the menu to show the error — but do NOT quit.
            if let menu = statusItem.menu,
               let item = menu.item(withTag: MenuTag.status.rawValue) {
                item.title = "Error: could not create event tap"
            }
            return
        }

        eventTap = tap
        globalEventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
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

        // Small delay so the menu bar has settled and we don't stack dialogs
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showLoginItemAlert()
        }
    }

    @available(macOS 13.0, *)
    private func showLoginItemAlert() {
        let alert = NSAlert()
        alert.messageText = "Start at Login?"
        alert.informativeText = "Would you like \(appName) to launch automatically when you log in?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        let response = alert.runModal()

        // Persist regardless of answer so we never ask again
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

// MARK: - Event Tap Callback (free function required by C API)

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Re-enable the tap if the system disabled it (e.g. timeout)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = globalEventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    let flags = event.flags.rawValue
    let fnPressed = (flags & kCGEventFlagMaskSecondaryFn) != 0
    let location = event.location

    switch type {

    // ── Mouse Down ──────────────────────────────────────────────────
    case .leftMouseDown:
        guard fnPressed else {
            return Unmanaged.passRetained(event)
        }
        middleClickSessionActive = true

        if let middleDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .otherMouseDown,
            mouseCursorPosition: location,
            mouseButton: .center
        ) {
            middleDown.post(tap: .cgSessionEventTap)
        }
        return nil

    // ── Mouse Up ────────────────────────────────────────────────────
    case .leftMouseUp:
        guard middleClickSessionActive else {
            return Unmanaged.passRetained(event)
        }
        middleClickSessionActive = false

        if let middleUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .otherMouseUp,
            mouseCursorPosition: location,
            mouseButton: .center
        ) {
            middleUp.post(tap: .cgSessionEventTap)
        }
        return nil

    // ── Mouse Dragged ───────────────────────────────────────────────
    case .leftMouseDragged:
        guard middleClickSessionActive else {
            return Unmanaged.passRetained(event)
        }

        if let middleDrag = CGEvent(
            mouseEventSource: nil,
            mouseType: .otherMouseDragged,
            mouseCursorPosition: location,
            mouseButton: .center
        ) {
            middleDrag.post(tap: .cgSessionEventTap)
        }
        return nil

    default:
        return Unmanaged.passRetained(event)
    }
}

