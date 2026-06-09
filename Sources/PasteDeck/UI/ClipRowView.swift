import SwiftUI
import AppKit

struct ClipRowView: View {
    let item: ClipItemDTO
    let onTap: () -> Void
    let onPin: () -> Void

    @State private var isHovered = false
    @State private var thumbnail: NSImage?

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Type icon or thumbnail
            typeIcon
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 0) {
                Text(displayText)
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }

            Spacer(minLength: 4)

            if isHovered {
                Button(action: onPin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 10))
                        .foregroundColor(item.isPinned ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin" : "Pin")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture { onTap() }
        .background(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
        .onAppear {
            loadThumbnail()
        }
    }

    // MARK: - Type Icon

    @ViewBuilder
    private var typeIcon: some View {
        if item.type == .image, let thumbnail = thumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: iconName)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private var iconName: String {
        switch item.type {
        case .text:     return "text.alignleft"
        case .image:    return "photo"
        case .filePath: return "doc"
        case .html:     return "chevron.left.slash.chevron.right"
        }
    }

    // MARK: - Display Text

    private var displayText: String {
        item.displayText
    }

    // MARK: - Thumbnail

    private func loadThumbnail() {
        guard item.type == .image, let url = item.imageURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: url) {
                let thumbnail = image.thumbnail(size: NSSize(width: 56, height: 56))
                DispatchQueue.main.async {
                    self.thumbnail = thumbnail
                }
            }
        }
    }
}

// MARK: - NSImage Thumbnail Helper

private extension NSImage {
    func thumbnail(size: NSSize) -> NSImage {
        let ratio = min(size.width / self.size.width, size.height / self.size.height)
        let newSize = NSSize(
            width: self.size.width * ratio,
            height: self.size.height * ratio
        )
        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        self.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .copy,
            fraction: 1.0
        )
        thumbnail.unlockFocus()
        return thumbnail
    }
}
