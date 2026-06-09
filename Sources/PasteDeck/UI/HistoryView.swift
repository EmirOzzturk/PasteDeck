import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var clipStore: ClipStore
    @State private var searchText = ""
    @State private var items: [ClipItemDTO] = []

    var filteredItems: [ClipItemDTO] {
        if searchText.isEmpty { return items }
        return clipStore.search(searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
            Divider()

            if filteredItems.isEmpty {
                emptyState
            } else {
                listView
            }

            Divider()
            footer
        }
        .frame(width: 320, height: 480)
        .onAppear { refreshItems() }
        .onReceive(
            Timer.publish(every: 2, on: .main, in: .common).autoconnect()
        ) { _ in refreshItems() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "No clips yet" : "No results")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            if searchText.isEmpty {
                Text("Copy something to get started")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listView: some View {
        List(filteredItems) { item in
            ClipRowView(
                item: item,
                onTap: { selectClip(item) },
                onPin: { clipStore.togglePin(id: item.id) }
            )
            .id(item.id)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .contextMenu {
                Button("Copy") { selectClip(item) }
                Button(item.isPinned ? "Unpin" : "Pin") {
                    clipStore.togglePin(id: item.id)
                }
                Divider()
                Button("Delete", role: .destructive) {
                    clipStore.delete(id: item.id)
                }
            }
        }
        .listStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text("\(items.count) clips")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Button { clearAll() } label: {
                Text("Clear All").font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    private func selectClip(_ item: ClipItemDTO) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        clipStore.touch(id: item.id)
        NSApp.keyWindow?.close()
    }

    private func clearAll() {
        clipStore.clearAll()
        refreshItems()
    }

    private func refreshItems() {
        items = clipStore.fetchAll()
    }
}
