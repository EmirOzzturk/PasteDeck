import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var clipWindow: NSWindow!
    private var clipStore: ClipStore!
    private var monitor: ClipboardMonitor!
    private let shortcutManager = ShortcutManager()

    /// Açılmadan önceki aktif uygulamanın PID'si
    private var previousAppPID: pid_t = 0
    /// Kapandıktan sonra yapıştırma yapılacak mı?
    private var shouldPasteAfterClose = false
    /// Dış tıklamaları yakalamak için event monitor
    private var outsideClickMonitor: Any?

    // MARK: - UserDefaults Keys

    private let positionKey = "PasteDeck.windowFrame"

    func applicationDidFinishLaunching(_ notification: Notification) {
        clipStore = ClipStore()

        // Clipboard izleyiciyi başlat
        monitor = ClipboardMonitor(store: clipStore)
        monitor.start()

        // Menü bar öğesi
        setupMenuBar()

        // Pencere
        setupWindow()

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
            button.action = #selector(toggleWindow)
            button.target = self
        }
    }

    // MARK: - Window

    private func setupWindow() {
        let frame = savedFrame()
        clipWindow = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        clipWindow.title = "PasteDeck"
        clipWindow.level = .floating
        clipWindow.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        clipWindow.delegate = self

        let historyView = HistoryView(clipStore: clipStore)
        var view = historyView
        view.onClipSelected = { [weak self] in
            self?.shouldPasteAfterClose = true
        }
        view.onDismiss = { [weak self] in
            self?.closeWindow()
        }

        clipWindow.contentView = FirstResponderHostingView(rootView: view)
        clipWindow.initialFirstResponder = clipWindow.contentView
    }

    private func savedFrame() -> NSRect {
        if let data = UserDefaults.standard.string(forKey: positionKey) {
            let frame = NSRectFromString(data)
            if !frame.isEmpty, frame.width >= 200, frame.height >= 200 {
                if let screen = NSScreen.main, screen.visibleFrame.intersects(frame) {
                    return frame
                }
            }
        }
        return defaultFrame()
    }

    private func defaultFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 200, y: 200, width: 320, height: 480)
        }
        let visible = screen.visibleFrame
        let w: CGFloat = 320, h: CGFloat = 480
        let x = visible.midX - w / 2
        let y = visible.midY - h / 2
        return NSRect(x: x, y: y, width: w, height: h)
    }

    private func saveFrame() {
        UserDefaults.standard.set(
            NSStringFromRect(clipWindow.frame),
            forKey: positionKey
        )
    }

    @objc private func toggleWindow() {
        if clipWindow.isVisible {
            closeWindow()
        } else {
            showWindow()
        }
    }

    private func showWindow() {
        previousAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0

        clipWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // SwiftUI view hierarchy'nin hazır olması için kısa bekle, sonra focus ver
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.clipWindow.makeFirstResponder(self?.clipWindow.contentView)
        }

        startOutsideClickMonitoring()
    }

    private func closeWindow() {
        saveFrame()
        clipWindow.orderOut(nil)
        stopOutsideClickMonitoring()

        // Auto-paste
        if shouldPasteAfterClose, previousAppPID != 0 {
            shouldPasteAfterClose = false
            if let app = NSRunningApplication(processIdentifier: previousAppPID) {
                app.activate()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendPaste(to: self.previousAppPID)
            }
        }
    }

    // MARK: - Outside Click

    private func startOutsideClickMonitoring() {
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self, self.clipWindow.isVisible else { return }
            _ = event.locationInWindow
            // Global monitörde locationInWindow nil, ekran koordinatı kullan
            let screenPoint = NSEvent.mouseLocation
            if !self.clipWindow.frame.contains(screenPoint) {
                DispatchQueue.main.async {
                    self.closeWindow()
                }
            }
        }
    }

    private func stopOutsideClickMonitoring() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        closeWindow()
        return false // Kendi closeWindow metodumuzu kullan
    }

    func windowDidResignKey(_ notification: Notification) {
        // Başka pencereye tıklanınca kapat
        if clipWindow.isVisible {
            closeWindow()
        }
    }

    func windowDidMove(_ notification: Notification) {
        saveFrame()
    }

    // MARK: - Auto Paste

    private func sendPaste(to pid: pid_t) {
        let vKey: CGKeyCode = 9

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
            guard let self else { return }

            if self.clipWindow.isVisible {
                self.closeWindow()
            } else {
                NSApp.activate(ignoringOtherApps: true)
                self.showWindow()
            }
        }

        shortcutManager.register()

        if !shortcutManager.isRegistered {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.shortcutManager.showPermissionAlert()
            }
        }
    }
}
