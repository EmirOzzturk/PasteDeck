import AppKit
import Foundation

final class PasteboardObserver {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    init() {
        self.lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring(onChange: @escaping (String, ClipType) -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.pasteboard.changeCount != self.lastChangeCount else { return }

            self.lastChangeCount = self.pasteboard.changeCount

            // Önce text kontrol et
            if let text = self.pasteboard.string(forType: .string) {
                onChange(text, .text)
                return
            }

            // HTML var mı?
            if let htmlData = self.pasteboard.data(forType: .html),
               let htmlString = String(data: htmlData, encoding: .utf8) {
                onChange(htmlString, .html)
                return
            }

            // Dosya yolu var mı?
            if let fileURLs = self.pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
               !fileURLs.isEmpty {
                let paths = fileURLs.map { $0.path }.joined(separator: "\n")
                onChange(paths, .filePath)
                return
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
