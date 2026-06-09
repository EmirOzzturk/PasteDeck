import SwiftUI

struct ClipRowView: View {
    let item: ClipItemDTO
    let onTap: () -> Void
    let onPin: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: item.type == .filePath ? "doc" : "text.alignleft")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .lineLimit(2)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)

                Text(item.createdAt, style: .relative)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
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
    }
}
