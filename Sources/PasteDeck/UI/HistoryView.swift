import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var clipStore: ClipStore
    @State private var searchText = ""
    @State private var items: [ClipItem] = []
    @State private var refreshID = UUID()

    var filteredItems: [ClipItem] {
        if searchText.isEmpty {
            return items
        }
        return clipStore.search(searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Arama çubuğu
            SearchBar(text: $searchText)

            Divider()

            // Liste
            if filteredItems.isEmpty {
                emptyState
            } else {
                listView
            }

            // Alt bilgi
            Divider()
            footer
        }
        .frame(width: 320, height: 480)
        .onAppear {
            refreshItems()
        }
        .onReceive(
            Timer.publish(every: 2, on: .main, in: .common).autoconnect()
        ) { _ in
            refreshItems()
        }
    }

    // MARK: - Empty State

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

    // MARK: - List View

    private var listView: some View {
        ScrollViewReader { proxy in
            List(filteredItems) { item in
                ClipRowView(
                    item: item,
                    onTap: { selectClip(item) },
                    onPin: { clipStore.togglePin(item) }
                )
                .id(item.id)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .contextMenu {
                    Button("Copy") { selectClip(item) }
                    Button(item.isPinned ? "Unpin" : "Pin") {
                        clipStore.togglePin(item)
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        clipStore.delete(item)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("\(items.count) clips")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Spacer()

            Button {
                clearAll()
            } label: {
                Text("Clear All")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func selectClip(_ item: ClipItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        clipStore.touch(item)

        // Popover'ı kapat
        NSApp.keyWindow?.close()
    }

    private func clearAll() {
        for item in items where !item.isPinned {
            clipStore.delete(item)
        }
        refreshItems()
    }

    private func refreshItems() {
        items = clipStore.fetchAll()
    }
}
