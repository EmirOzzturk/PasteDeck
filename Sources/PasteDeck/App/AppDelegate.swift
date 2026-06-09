import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var clipStore: ClipStore!
    private var monitor: ClipboardMonitor!
    private let shortcutManager = ShortcutManager()

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
        popover.contentViewController = NSHostingController(
            rootView: HistoryView(clipStore: clipStore)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Shortcut

    private func setupShortcut() {
        shortcutManager.onHotKey = { [weak self] in
            guard let self, let button = self.statusItem?.button else { return }

            if self.popover.isShown {
                self.popover.performClose(nil)
            } else {
                // Önce uygulamayı öne getir
                NSApp.activate(ignoringOtherApps: true)

                self.popover.show(
                    relativeTo: button.bounds,
                    of: button,
                    preferredEdge: .minY
                )
                self.popover.contentViewController?.view.window?.makeKey()
            }
        }

        shortcutManager.register()
    }
}
