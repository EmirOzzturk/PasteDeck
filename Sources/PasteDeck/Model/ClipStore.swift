import Foundation
import AppKit
import CryptoKit

/// Nonisolated — computed once, used by both ClipEntry and ClipStore
nonisolated let pasteDeckImagesDirectory: URL = {
    let appSupport = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/PasteDeck/images")
    try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
    return appSupport
}()

@MainActor
final class ClipStore: ObservableObject {
    private let maxItems = 50
    private let storeURL: URL

    /// Images are stored in a subdirectory
    static var imagesDirectory: URL { pasteDeckImagesDirectory }

    private var entries: [ClipEntry] = []

    init() {
        let appSupport = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PasteDeck")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        self.storeURL = appSupport.appendingPathComponent("clips.json")
        loadFromDisk()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([ClipEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded

        // Orphan temizliği: dosyası silinmiş image entry'leri kaldır
        var needsSave = false
        entries.removeAll { entry in
            guard entry.type == .image else { return false }
            let fileURL = pasteDeckImagesDirectory.appendingPathComponent(entry.content)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                needsSave = true
                return true
            }
            return false
        }

        // Orphan temizliği: entry'si olmayan image dosyalarını sil
        let validFileNames = Set(entries.filter { $0.type == .image }.map { $0.content })
        if let files = try? FileManager.default.contentsOfDirectory(atPath: pasteDeckImagesDirectory.path) {
            for file in files where !validFileNames.contains(file) {
                let url = pasteDeckImagesDirectory.appendingPathComponent(file)
                try? FileManager.default.removeItem(at: url)
                needsSave = true
            }
        }

        if needsSave {
            saveToDisk()
        }
    }

    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }

    // MARK: - Add Text / HTML / RTF / FilePath

    func add(_ content: String, type: ClipType = .text) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Duplicate kontrolü (aynı içerik + aynı tip)
        if let index = entries.firstIndex(where: { $0.content == trimmed && $0.type == type }) {
            entries[index].createdAt = Date()
            saveToDisk()
            objectWillChange.send()
            return
        }

        let entry = ClipEntry(content: trimmed, type: type)
        entries.insert(entry, at: 0)
        saveToDisk()
        objectWillChange.send()

        pruneOldest()
    }

    // MARK: - Add Image

    func addImage(_ imageData: Data) {
        let imageID = UUID()
        let fileName = "\(imageID.uuidString).png"
        let fileURL = pasteDeckImagesDirectory.appendingPathComponent(fileName)

        // TIFF → PNG dönüşümü (macOS pasteboard çoğunlukla TIFF kullanır)
        let pngData: Data
        if let image = NSImage(data: imageData),
           let converted = image.pngData() {
            pngData = converted
        } else {
            pngData = imageData  // fallback: raw data
        }

        do {
            try pngData.write(to: fileURL, options: .atomic)
        } catch {
            print("[PasteDeck] Failed to save image: \(error)")
            return
        }

        // Duplicate check: PNG data hash karşılaştırması
        let newHash = pngData.sha256Hash()
        if let existing = entries.first(where: { entry in
            guard entry.type == .image else { return false }
            let existingURL = pasteDeckImagesDirectory.appendingPathComponent(entry.content)
            guard let existingData = try? Data(contentsOf: existingURL) else { return false }
            return existingData.sha256Hash() == newHash
        }) {
            // Duplicate found — delete the new file, update timestamp
            try? FileManager.default.removeItem(at: fileURL)
            if let index = entries.firstIndex(where: { $0.id == existing.id }) {
                entries[index].createdAt = Date()
                saveToDisk()
                objectWillChange.send()
            }
            return
        }

        let entry = ClipEntry(content: fileName, type: .image)
        entries.insert(entry, at: 0)
        saveToDisk()
        objectWillChange.send()

        pruneOldest()
    }

    // MARK: - Image URL helper

    func imageURL(for clipID: UUID) -> URL? {
        guard let entry = entries.first(where: { $0.id == clipID }),
              entry.type == .image else { return nil }
        return Self.imagesDirectory.appendingPathComponent(entry.content)
    }

    // MARK: - Write to Pasteboard

    func writeToPasteboard(clipID: UUID) {
        guard let entry = entries.first(where: { $0.id == clipID }) else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch entry.type {
        case .text, .filePath:
            pasteboard.setString(entry.content, forType: .string)

        case .html:
            // Write both HTML data and plain text
            pasteboard.setString(entry.content, forType: .string)
            if let htmlData = entry.content.data(using: .utf8) {
                pasteboard.setData(htmlData, forType: .html)
            }

        case .rtf:
            pasteboard.setString(entry.content, forType: .string)

        case .image:
            let fileURL = Self.imagesDirectory.appendingPathComponent(entry.content)
            if let imageData = try? Data(contentsOf: fileURL) {
                // Try PNG first, fall back to TIFF
                if let image = NSImage(data: imageData) {
                    if let pngData = image.pngData() {
                        pasteboard.setData(pngData, forType: .png)
                    } else if let tiffData = image.tiffRepresentation {
                        pasteboard.setData(tiffData, forType: .tiff)
                    }
                } else {
                    // Raw write
                    pasteboard.setData(imageData, forType: .png)
                }
            }
        }

        touch(id: clipID)
    }

    // MARK: - Fetch

    func fetchAll(limit: Int = 50) -> [ClipItemDTO] {
        let sorted = sortPinnedFirst(entries)
        return Array(sorted.prefix(limit)).map { $0.toClipItem(context: ()) }
    }

    // MARK: - Search

    func search(_ query: String) -> [ClipItemDTO] {
        let lowercased = query.lowercased()
        let filtered = entries.filter {
            $0.displayText.lowercased().contains(lowercased)
        }
        return sortPinnedFirst(filtered).map { $0.toClipItem(context: ()) }
    }

    /// Pinned öğeleri listenin başına taşı
    private func sortPinnedFirst(_ items: [ClipEntry]) -> [ClipEntry] {
        items.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.createdAt > b.createdAt
        }
    }

    // MARK: - Delete

    func delete(id: UUID) {
        if let entry = entries.first(where: { $0.id == id }), entry.type == .image {
            let fileURL = Self.imagesDirectory.appendingPathComponent(entry.content)
            try? FileManager.default.removeItem(at: fileURL)
        }
        entries.removeAll { $0.id == id }
        saveToDisk()
        objectWillChange.send()
    }

    // MARK: - Pin

    func togglePin(id: UUID) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].isPinned.toggle()
            saveToDisk()
        }
    }

    // MARK: - Touch

    func touch(id: UUID) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].createdAt = Date()
            saveToDisk()
        }
    }

    // MARK: - Clear All (pinned hariç)

    func clearAll() {
        // Delete image files for unpinned image entries
        for entry in entries where !entry.isPinned && entry.type == .image {
            let fileURL = Self.imagesDirectory.appendingPathComponent(entry.content)
            try? FileManager.default.removeItem(at: fileURL)
        }
        entries.removeAll { !$0.isPinned }
        saveToDisk()
        objectWillChange.send()
    }

    // MARK: - Prune

    private func pruneOldest() {
        guard entries.count > maxItems else { return }
        let unpinned = entries.filter { !$0.isPinned }.sorted { $0.createdAt < $1.createdAt }
        let excess = entries.count - maxItems
        let toRemove = unpinned.prefix(excess)

        for entry in toRemove where entry.type == .image {
            let fileURL = Self.imagesDirectory.appendingPathComponent(entry.content)
            try? FileManager.default.removeItem(at: fileURL)
        }

        let idsToRemove = Set(toRemove.map { $0.id })
        entries.removeAll { idsToRemove.contains($0.id) }
        saveToDisk()
    }
}

// MARK: - NSImage Helpers

private extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

// MARK: - Data SHA256 Helper

private extension Data {
    func sha256Hash() -> String {
        SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }
}
