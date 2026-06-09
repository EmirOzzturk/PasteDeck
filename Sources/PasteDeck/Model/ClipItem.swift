import Foundation
import SwiftData

enum ClipType: String, Codable, CaseIterable {
    case text
    case image
    case filePath
    case html
}

@Model
final class ClipItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var typeRaw: String
    var createdAt: Date
    var isPinned: Bool

    var type: ClipType {
        get { ClipType(rawValue: typeRaw) ?? .text }
        set { typeRaw = newValue.rawValue }
    }

    init(content: String, type: ClipType = .text) {
        self.id = UUID()
        self.content = content
        self.typeRaw = type.rawValue
        self.createdAt = Date()
        self.isPinned = false
    }
}
