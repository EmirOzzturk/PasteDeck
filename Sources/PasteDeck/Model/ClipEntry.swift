import Foundation

enum ClipType: String, Codable, CaseIterable {
    case text
    case image
    case filePath
    case html
}

struct ClipEntry: Codable, Identifiable {
    var id: UUID
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

    func toClipItem(context: Void) -> ClipItemDTO {
        ClipItemDTO(
            id: id,
            content: content,
            type: type,
            createdAt: createdAt,
            isPinned: isPinned
        )
    }
}

/// SwiftData'sız, ObservableObject ile kullanılabilir DTO
struct ClipItemDTO: Identifiable {
    let id: UUID
    let content: String
    let type: ClipType
    let createdAt: Date
    let isPinned: Bool
}
