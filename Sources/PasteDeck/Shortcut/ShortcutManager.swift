import Carbon
import AppKit

/// Global klavye kısayolu yöneticisi (V1.5).
/// Cmd+Shift+V ile PasteDeck popover'ını açar.
final class ShortcutManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onHotKey: (() -> Void)?

    private static let hotKeyID = UInt32(1)
    private static let eventSpec = EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: OSType(kEventHotKeyPressed)
    )

    // MARK: - Register

    func register() {
        // Accessibility izni kontrol et
        guard checkAccessibility() else { return }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = 0x50444B54 // "PDKT"
        hotKeyID.id = Self.hotKeyID

        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),              // V tuşu
            UInt32(cmdKey | shiftKey),       // Cmd + Shift
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else { return }

        // Event handler
        var spec = Self.eventSpec
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData else { return -1 }
                let manager = Unmanaged<ShortcutManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotKeyEvent(event)
            },
            1,
            &spec,
            selfPtr,
            &handlerRef
        )
    }

    // MARK: - Unregister

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
    }

    // MARK: - Event Handling

    private func handleHotKeyEvent(_ event: EventRef?) -> OSStatus {
        // Hotkey tetiklendi — popover'ı aç/kapat
        DispatchQueue.main.async { [weak self] in
            self?.onHotKey?()
        }
        return noErr
    }

    // MARK: - Accessibility Permission

    private func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
