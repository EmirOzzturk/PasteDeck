import Foundation
import AppKit

enum ClipType: String, Codable, CaseIterable {
    case text
    case image
    case filePath
    case html
    case rtf
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

    /// UI'da gösterilecek metin (HTML tag'leri strip edilir)
    var displayText: String {
        switch type {
        case .html:
            return Self.htmlToPlainText(content)
        case .image:
            return "[Image]"
        case .text, .filePath, .rtf:
            return content
        }
    }

    /// Image tipi için dosya yolu
    var imageURL: URL? {
        guard type == .image else { return nil }
        return pasteDeckImagesDirectory.appendingPathComponent(content)
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
            isPinned: isPinned,
            displayText: displayText,
            imageURL: imageURL
        )
    }

    // MARK: - HTML Strip

    static func htmlToPlainText(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return html
    }
}

/// SwiftData'sız, ObservableObject ile kullanılabilir DTO
struct ClipItemDTO: Identifiable {
    let id: UUID
    let content: String
    let type: ClipType
    let createdAt: Date
    let isPinned: Bool
    let displayText: String
    let imageURL: URL?
}
