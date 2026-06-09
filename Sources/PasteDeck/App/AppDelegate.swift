import AppKit
import SwiftUI
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var clipStore: ClipStore!
    private var monitor: ClipboardMonitor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // SwiftData container
        let container: ModelContainer
        do {
            container = try ModelContainer(for: ClipItem.self)
        } catch {
            fatalError("SwiftData container oluşturulamadı: \(error)")
        }

        let context = container.mainContext
        clipStore = ClipStore(modelContext: context)

        // Clipboard izleyiciyi başlat
        monitor = ClipboardMonitor(store: clipStore)
        monitor.start()

        // Menü bar öğesi
        setupMenuBar()

        // Popover
        setupPopover()
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
            // Popover açıldığında her zaman öne getir
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
