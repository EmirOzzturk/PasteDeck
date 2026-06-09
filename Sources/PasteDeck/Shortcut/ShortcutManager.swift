import Carbon
import AppKit

/// Global klavye kısayolu yöneticisi (V1.5).
/// Cmd+Shift+V ile PasteDeck popover'ını açar.
final class ShortcutManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onHotKey: (() -> Void)?
    private(set) var isRegistered = false

    private static let hotKeyID = UInt32(1)
    private static let eventSpec = EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: OSType(kEventHotKeyPressed)
    )

    // MARK: - Register

    func register() {
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

        // İzin yoksa RegisterEventHotKey başarısız olur.
        guard status == noErr else {
            isRegistered = false
            return
        }

        isRegistered = true

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

    /// Kullanıcıyı doğrudan Accessibility ayarlarına yönlendir
    func requestPermission() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Kullanıcıya izin vermesi gerektiğini söyleyen alert göster
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "PasteDeck needs accessibility access to use the Cmd+Shift+V shortcut.\n\nOpen System Settings > Privacy & Security > Accessibility, then enable PasteDeck and restart the app."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            requestPermission()
        }
    }

    private func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
