//
//  BoardView.swift
//  Bolito
//
//  Created by Alex Marcelle on 01/10/26.
//

import SwiftUI
import SwiftData

struct BoardView: View {
    private enum ColumnDropTarget: Equatable {
        case before(UUID)
        case end
    }

    let board: Board
    
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    
    @State var isCreateColumnModalOpen = false
    @State private var newColumnTitle = ""
    @State private var newColumnColor: Color = .accentColor
    @State private var activeColumnDropTarget: ColumnDropTarget?

    private var selectedLocale: Locale {
        AppLanguage(rawValue: appLanguage)?.locale ?? .autoupdatingCurrent
    }

    private var localizer: AppLocalizer {
        AppLocalizer(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }
    
    var body: some View {
        Group {
            if(board.columns.isEmpty) {
                ContentUnavailableView {
                    Label {
                        Text(verbatim: localizer.string("columns.empty.title"))
                    } icon: {
                        Image(systemName: "rectangle.split.3x1")
                    }
                } description: {
                    Text(verbatim: localizer.string("columns.empty.description"))
                }
            }
            else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(board.columns.sorted { $0.position < $1.position }) { column in
                            draggableColumn(column)
                        }

                        Color.clear
                            .frame(width: activeColumnDropTarget == .end ? 44 : 28, height: 500)
                            .contentShape(Rectangle())
                            .overlay(alignment: .leading) {
                                if activeColumnDropTarget == .end {
                                    columnInsertionIndicator
                                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                                }
                            }
                            .dropDestination(for: String.self, isEnabled: true) { items, _ in
                                handleColumnDrop(items, before: nil)
                            }
                            .onDropSessionUpdated { session in
                                updateColumnDropTarget(.end, for: session)
                            }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCreateColumnModalOpen = true
                } label: {
                    Label {
                        Text(verbatim: localizer.string("columns.new"))
                    } icon: {
                        Image(systemName: "plus.rectangle.portrait")
                    }
                }
            }
        }
        .sheet(isPresented: $isCreateColumnModalOpen) {
            createColumnSheet
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
        }
        .animation(.snappy(duration: 0.18), value: activeColumnDropTarget)
    }

    private var columnInsertionIndicator: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 4, height: 500)
            .shadow(color: Color.accentColor.opacity(0.45), radius: 4)
    }

    private func draggableColumn(_ column: Column) -> some View {
        ColumnView(column: column)
            .draggable("column:\(column.id.uuidString)") {
                Label(column.title, systemImage: "rectangle.split.3x1")
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .overlay(alignment: .leading) {
                if isDropTarget(before: column.id) {
                    columnInsertionIndicator
                        .offset(x: -10)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
            }
            .dropDestination(for: String.self, isEnabled: true) { items, _ in
                handleColumnDrop(items, before: column.id)
            }
            .onDropSessionUpdated { session in
                updateColumnDropTarget(.before(column.id), for: session)
            }
    }

    private func isDropTarget(before columnId: UUID) -> Bool {
        activeColumnDropTarget == .before(columnId)
    }

    private func handleColumnDrop(_ items: [String], before targetId: UUID?) {
        guard let item = items.first,
              item.hasPrefix("column:"),
              let draggedId = UUID(uuidString: String(item.dropFirst("column:".count))) else {
            return
        }

        moveColumn(withId: draggedId, before: targetId)
        activeColumnDropTarget = nil
    }

    private func updateColumnDropTarget(_ target: ColumnDropTarget, for session: DropSession) {
        switch session.phase {
        case .entering, .active:
            activeColumnDropTarget = target
        case .exiting, .ended, .dataTransferCompleted:
            if activeColumnDropTarget == target {
                activeColumnDropTarget = nil
            }
        @unknown default:
            if activeColumnDropTarget == target {
                activeColumnDropTarget = nil
            }
        }
    }

    private func moveColumn(withId draggedId: UUID, before targetId: UUID?) {
        guard draggedId != targetId,
              let draggedColumn = board.columns.first(where: { $0.id == draggedId }) else {
            return
        }

        var orderedColumns = board.columns
            .filter { $0.id != draggedId }
            .sorted { $0.position < $1.position }

        let insertionIndex: Int

        if let targetId,
           let targetIndex = orderedColumns.firstIndex(where: { $0.id == targetId }) {
            insertionIndex = targetIndex
        } else {
            insertionIndex = orderedColumns.endIndex
        }

        orderedColumns.insert(draggedColumn, at: insertionIndex)

        withAnimation(.snappy(duration: 0.22)) {
            for (index, column) in orderedColumns.enumerated() {
                column.position = Int16(index)
            }
        }

        try? modelContext.save()
    }
    
    private var createColumnSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: localizer.string("columns.name")).font(.headline)
            TextField(localizer.string("columns.name.placeholder"), text: $newColumnTitle).frame(width: 300)
            
            ColorPicker(localizer.string("columns.color"), selection: $newColumnColor)
            
            HStack {
                Spacer()
                
                Button(localizer.string("common.cancel")) {
                    newColumnTitle = ""
                    isCreateColumnModalOpen = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button(localizer.string("common.create")) {
                    let nextPosition: Int16 = (board.columns.map(\.position).max() ?? -1) + 1
                    
                    let column = Column(
                        title: newColumnTitle,
                        color: newColumnColor.toHex(),
                        position: nextPosition
                    )
                    board.columns.append(column)
                    modelContext.insert(column)
                    
                    isCreateColumnModalOpen = false
                    newColumnColor = .accentColor
                    newColumnTitle = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newColumnTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
    }
}
