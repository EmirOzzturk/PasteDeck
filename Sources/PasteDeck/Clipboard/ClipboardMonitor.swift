import Foundation

@MainActor
final class ClipboardMonitor {
    private let observer = PasteboardObserver()
    private let store: ClipStore

    init(store: ClipStore) {
        self.store = store
    }

    func start() {
        observer.startMonitoring { [weak self] text, imageData, type in
            guard let self else { return }
            DispatchQueue.main.async {
                if type == .image, let imageData = imageData {
                    self.store.addImage(imageData)
                } else if let text = text {
                    self.store.add(text, type: type)
                }
            }
        }
    }

    func stop() {
        observer.stopMonitoring()
    }
}
