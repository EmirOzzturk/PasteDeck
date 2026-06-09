import Foundation

/// PasteboardObserver ile ClipStore arasında köprü.
/// Clipboard değişikliklerini yakalar, ClipStore'a iletir.
@MainActor
final class ClipboardMonitor {
    private let observer = PasteboardObserver()
    private let store: ClipStore

    init(store: ClipStore) {
        self.store = store
    }

    func start() {
        observer.startMonitoring { [weak self] text, type in
            guard let self else { return }
            self.store.add(text, type: type)
        }
    }

    func stop() {
        observer.stopMonitoring()
    }
}
