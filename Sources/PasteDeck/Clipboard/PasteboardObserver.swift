import AppKit
import Foundation

final class PasteboardObserver {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    /// Callback: text?, imageData?, type
    typealias ChangeCallback = (String?, Data?, ClipType) -> Void

    init() {
        self.lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring(onChange: @escaping ChangeCallback) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self else { return }
            let current = self.pasteboard.changeCount
            guard current != self.lastChangeCount else { return }

            self.lastChangeCount = current

            // Kendi writeToPasteboard çağrımızdan gelen değişiklikleri yok say
            if ClipStore.suppressObserver { return }

            // ⚠️ ÖNEMLİ: Image tipleri HER ZAMAN önce kontrol edilmeli.
            // Birçok uygulama (tarayıcılar) "Copy Image" yapınca pasteboard'a
            // hem URL string'i hem image data koyar — önce image yakalanmazsa
            // string olarak kaydedilir.

            // 1. Image (TIFF) — en yaygın format
            if let imageData = self.pasteboard.data(forType: .tiff) {
                onChange(nil, imageData, .image)
                return
            }

            // 2. Image (PNG)
            if let imageData = self.pasteboard.data(forType: .png) {
                onChange(nil, imageData, .image)
                return
            }

            // 3. File paths
            if let fileURLs = self.pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
               !fileURLs.isEmpty {
                let paths = fileURLs.map { $0.path }.joined(separator: "\n")
                onChange(paths, nil, .filePath)
                return
            }

            // 4. HTML
            if let htmlData = self.pasteboard.data(forType: .html),
               let htmlString = String(data: htmlData, encoding: .utf8) {
                onChange(htmlString, nil, .html)
                return
            }

            // 5. Text — son çare
            if let text = self.pasteboard.string(forType: .string) {
                onChange(text, nil, .text)
                return
            }
        }

        if let timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}
