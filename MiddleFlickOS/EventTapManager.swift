import Cocoa
import ApplicationServices

final class EventTapManager {
    private var eventTap: CFMachPort?

    func start() -> Bool {
        let eventMask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            return false
        }

        eventTap = tap
        globalEventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        eventTap = nil
        globalEventTap = nil
    }
}

// MARK: - Event Tap Callback (free function required by C API)

/// Tracks whether we're in an active Fn+Click → middle-click session.
private var middleClickSessionActive = false

/// Stored globally so the C callback can re-enable it on timeout.
private var globalEventTap: CFMachPort?

/// Fn flag constant (NX_SECONDARYFNMASK)
private let kCGEventFlagMaskSecondaryFn: UInt64 = 0x00800000

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

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
