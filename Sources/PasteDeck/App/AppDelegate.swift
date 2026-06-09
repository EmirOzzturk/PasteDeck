import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var clipStore: ClipStore!
    private var monitor: ClipboardMonitor!
    private let shortcutManager = ShortcutManager()

    /// Popover açılmadan önceki aktif uygulamanın PID'si
    private var previousAppPID: pid_t = 0
    /// Popover kapandıktan sonra yapıştırma yapılacak mı?
    private var shouldPasteAfterClose = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        clipStore = ClipStore()

        // Clipboard izleyiciyi başlat
        monitor = ClipboardMonitor(store: clipStore)
        monitor.start()

        // Menü bar öğesi
        setupMenuBar()

        // Popover
        setupPopover()

        // Global kısayol (Cmd+Shift+V)
        setupShortcut()
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutManager.unregister()
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "list.clipboard",
                accessibilityDescription: "PasteDeck"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 480)
        popover.behavior = .transient
        popover.delegate = self

        var historyView = HistoryView(clipStore: clipStore)
        historyView.onClipSelected = { [weak self] in
            self?.shouldPasteAfterClose = true
        }
        popover.contentViewController = NSHostingController(
            rootView: historyView
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover(button: button)
        }
    }

    private func showPopover(button: NSStatusBarButton) {
        // Açılmadan önceki aktif uygulamayı kaydet
        previousAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0

        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        if let window = popover.contentViewController?.view.window {
            window.makeKey()
            window.makeFirstResponder(popover.contentViewController?.view)
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        guard shouldPasteAfterClose, previousAppPID != 0 else { return }
        shouldPasteAfterClose = false

        // Önceki uygulamayı tekrar aktif et
        if let app = NSRunningApplication(processIdentifier: previousAppPID) {
            app.activate()
        }

        // Cmd+V gönder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sendPaste(to: self.previousAppPID)
        }
    }

    private func sendPaste(to pid: pid_t) {
        let vKey: CGKeyCode = 9 // kVK_ANSI_V

        func postKey(_ down: Bool) {
            guard let event = CGEvent(
                keyboardEventSource: nil,
                virtualKey: vKey,
                keyDown: down
            ) else { return }
            event.flags = .maskCommand
            event.postToPid(pid)
        }

        postKey(true)
        usleep(10_000)
        postKey(false)
    }

    // MARK: - Shortcut

    private func setupShortcut() {
        shortcutManager.onHotKey = { [weak self] in
            guard let self, let button = self.statusItem?.button else { return }

            if self.popover.isShown {
                self.popover.performClose(nil)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                self.showPopover(button: button)
                self.popover.contentViewController?.view.window?.makeKey()
            }
        }

        shortcutManager.register()

        // Kayıt başarısızsa kullanıcıya bildir
        if !shortcutManager.isRegistered {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.shortcutManager.showPermissionAlert()
            }
        }
    }
}
