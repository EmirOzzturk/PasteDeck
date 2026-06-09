import Foundation

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
            // MainActor üzerinde çalıştığından emin ol
            DispatchQueue.main.async {
                self.store.add(text, type: type)
            }
        }
    }

    func stop() {
        observer.stopMonitoring()
    }
}
