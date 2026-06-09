import Foundation
import SwiftData

@MainActor
final class ClipStore: ObservableObject {
    private let modelContext: ModelContext
    private let maxItems = 50

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Add

    func add(_ content: String, type: ClipType = .text) {
        // Duplicate kontrolü: aynı içerik zaten varsa, sadece tarihini güncelle
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { $0.content == trimmed }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.createdAt = Date()
            try? modelContext.save()
            return
        }

        // Yeni öğe ekle
        let item = ClipItem(content: trimmed, type: type)
        modelContext.insert(item)
        try? modelContext.save()

        // Limit aşımı kontrolü
        pruneOldest()
    }

    // MARK: - Fetch

    func fetchAll(limit: Int = 50) -> [ClipItem] {
        var descriptor = FetchDescriptor<ClipItem>(
            sortBy: [
                SortDescriptor(\.isPinned, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        descriptor.fetchLimit = limit

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Search

    func search(_ query: String) -> [ClipItem] {
        let lowercased = query.lowercased()
        var descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate { $0.content.localizedStandardContains(lowercased) },
            sortBy: [
                SortDescriptor(\.isPinned, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        descriptor.fetchLimit = 50

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Delete

    func delete(_ item: ClipItem) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    // MARK: - Pin

    func togglePin(_ item: ClipItem) {
        item.isPinned.toggle()
        try? modelContext.save()
    }

    // MARK: - Touch (listede üste taşı)

    func touch(_ item: ClipItem) {
        item.createdAt = Date()
        try? modelContext.save()
    }

    // MARK: - Prune

    func pruneOldest() {
        let all = fetchAll(limit: 999)
        guard all.count > maxItems else { return }

        // Pinned olmayanları tarihe göre sırala, en eskileri bul
        let unpinned = all.filter { !$0.isPinned }.sorted { $0.createdAt < $1.createdAt }
        let excess = all.count - maxItems

        for item in unpinned.prefix(excess) {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
