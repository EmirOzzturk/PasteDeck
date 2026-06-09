import Foundation

@MainActor
final class ClipStore: ObservableObject {
    private let maxItems = 50
    private let storeURL: URL
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
    }

    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }

    // MARK: - Add

    func add(_ content: String, type: ClipType = .text) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Duplicate kontrolü
        if let index = entries.firstIndex(where: { $0.content == trimmed }) {
            entries[index].createdAt = Date()
            saveToDisk()
            return
        }

        // Yeni öğe ekle
        let entry = ClipEntry(content: trimmed, type: type)
        entries.insert(entry, at: 0)
        saveToDisk()

        // Limit aşımı
        pruneOldest()
    }

    // MARK: - Fetch

    func fetchAll(limit: Int = 50) -> [ClipItemDTO] {
        let sorted = sortPinnedFirst(entries)
        return Array(sorted.prefix(limit)).map { $0.toClipItem(context: ()) }
    }

    // MARK: - Search

    func search(_ query: String) -> [ClipItemDTO] {
        let lowercased = query.lowercased()
        let filtered = entries.filter { $0.content.lowercased().contains(lowercased) }
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
        entries.removeAll { $0.id == id }
        saveToDisk()
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
        entries.removeAll { !$0.isPinned }
        saveToDisk()
    }

    // MARK: - Prune

    private func pruneOldest() {
        guard entries.count > maxItems else { return }
        let unpinned = entries.filter { !$0.isPinned }.sorted { $0.createdAt < $1.createdAt }
        let excess = entries.count - maxItems
        let idsToRemove = Set(unpinned.prefix(excess).map { $0.id })
        entries.removeAll { idsToRemove.contains($0.id) }
        saveToDisk()
    }
}
