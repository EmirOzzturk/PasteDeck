import Foundation
import SwiftData

@Model
final class TestClipItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var isPinned: Bool

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.isPinned = false
    }
}

let storeURL = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/PasteDeck/test.store")

// Clean up
try? FileManager.default.removeItem(at: storeURL)

let semaphore = DispatchSemaphore(value: 0)
var result = ""

Task { @MainActor in
    let config = ModelConfiguration(url: storeURL)
    let container = try ModelContainer(for: TestClipItem.self, configurations: config)
    let context = container.mainContext

    // Insert
    let item = TestClipItem(content: "Test from async CLI")
    context.insert(item)
    try context.save()

    // Fetch
    let descriptor = FetchDescriptor<TestClipItem>()
    let results = try context.fetch(descriptor)
    result = "OK: inserted and fetched \(results.count) items"
    semaphore.signal()
}

semaphore.wait()
print(result)
