import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var clipStore: ClipStore
    @State private var searchText = ""
    @State private var items: [ClipItemDTO] = []
    @State private var previousCount = 0
    @State private var selectedIndex: Int? = 0

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
        .focusable()
        .focusEffectDisabled()
        .onMoveCommand { direction in
            handleMoveCommand(direction)
        }
        .onKeyPress(.return) {
            confirmSelection()
            return .handled
        }
        .onKeyPress(.escape) {
            NSApp.keyWindow?.close()
            return .handled
        }
        .onAppear {
            refreshItems()
        }
        .onReceive(clipStore.objectWillChange) { _ in
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
            List(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                ClipRowView(
                    item: item,
                    onTap: {
                        selectedIndex = index
                        selectClip(item)
                    },
                    onPin: { clipStore.togglePin(id: item.id) }
                )
                .id(item.id)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .background(selectedIndex == index
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear)
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
            .onChange(of: items.count) { _, newCount in
                if newCount > previousCount {
                    selectedIndex = 0
                    if let firstID = filteredItems.first?.id {
                        proxy.scrollTo(firstID, anchor: .top)
                    }
                }
                previousCount = newCount
            }
            .onChange(of: selectedIndex) { _, newIndex in
                if let newIndex, newIndex < filteredItems.count {
                    let id = filteredItems[newIndex].id
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("\(items.count) clips")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text("↑↓ select  ↵ copy  esc close")
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

    // MARK: - Keyboard Handling

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        let count = filteredItems.count
        guard count > 0 else { return }

        switch direction {
        case .up:
            if let current = selectedIndex {
                selectedIndex = max(0, current - 1)
            } else {
                selectedIndex = 0
            }
        case .down:
            if let current = selectedIndex {
                selectedIndex = min(count - 1, current + 1)
            } else {
                selectedIndex = 0
            }
        default:
            break
        }
    }

    private func confirmSelection() {
        guard let index = selectedIndex, index < filteredItems.count else { return }
        selectClip(filteredItems[index])
    }

    // MARK: - Actions

    private func selectClip(_ item: ClipItemDTO) {
        clipStore.writeToPasteboard(clipID: item.id)
        NSApp.keyWindow?.close()

        // Otomatik yapıştır: popover kapandıktan sonra Cmd+V simüle et
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            simulatePaste()
        }
    }

    private func clearAll() {
        clipStore.clearAll()
        refreshItems()
    }

    private func refreshItems() {
        items = clipStore.fetchAll()
        if selectedIndex ?? 0 >= filteredItems.count {
            selectedIndex = max(0, filteredItems.count - 1)
        }
    }

    // MARK: - Auto Paste

    private func simulatePaste() {
        // AppleScript ile Cmd+V — Accessibility izni gerektirmez, System Events kullanır
        let script = "tell application \"System Events\" to keystroke \"v\" using command down"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}
