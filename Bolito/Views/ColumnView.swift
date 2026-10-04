//
//  ColumnView.swift
//  Bolito
//
//  Created by Alex Marcelle on 01/10/26.
//

import SwiftUI
import SwiftData

struct ColumnView: View {
    private enum TaskDropTarget: Equatable {
        case before(UUID)
        case end
    }

    let column: Column
    
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    
    @State private var isCreateTaskModalOpen = false
    @State private var isRenameColumnModalOpen = false
    @State private var renamedColumnTitle = ""
    @State private var newTaskTitle = ""
    @State private var newTaskDetails = ""
    @State private var newTaskTags: [TaskTag] = []
    
    @State private var hasDueDate = false
    @State private var newTaskDueDate = Date()
    
    @State private var selectedTask: Task?
    @State private var editingTask: Task?
    @State private var taskPendingDeletion: Task?
    @State private var isDeleteTaskConfirmationOpen = false

    @State private var editTaskTitle = ""
    @State private var editTaskDetails = ""
    @State private var editTaskHasDueDate = false
    @State private var editTaskDueDate = Date()
    @State private var editTaskTags: [TaskTag] = []

    @State private var activeDropTarget: TaskDropTarget?
    
    private var columnColor: Color {
        column.color.map { Color(hex: $0) } ?? .accentColor
    }

    private var selectedLocale: Locale {
        AppLanguage(rawValue: appLanguage)?.locale ?? .autoupdatingCurrent
    }

    private var localizer: AppLocalizer {
        AppLocalizer(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }

    private var availableBoardTags: [TaskTag] {
        guard let board = column.board else { return [] }

        var uniqueTags: [String: TaskTag] = [:]
        for tag in board.columns.flatMap(\.tasks).flatMap(\.taskTags) {
            uniqueTags[tag.id] = tag
        }

        return uniqueTags.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(column.title)
                .font(.headline)
            
            Group {
                if column.tasks.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text(verbatim: localizer.string("tasks.empty"))
                        } icon: {
                            Image(systemName: "plus")
                        }
                    } actions: {
                        Button {
                            isCreateTaskModalOpen = true
                        } label: {
                            Label {
                                Text(verbatim: localizer.string("common.create"))
                            } icon: {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .background {
                        if activeDropTarget == .end {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(columnColor.opacity(0.16))
                        }
                    }
                    .overlay {
                        if activeDropTarget == .end {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(columnColor, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                    }
                    .dropDestination(for: String.self, isEnabled: true) { ids, _ in
                        handleDrop(ids, before: nil)
                    }
                    .onDropSessionUpdated { session in
                        updateDropTarget(.end, for: session)
                    }
                }
                else {
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(column.tasks.sorted { $0.position < $1.position }) { task in
                                Button {
                                    selectedTask = task
                                } label: {
                                    taskCardLabel(for: task)
                                }
                                .draggable(task.id.uuidString)
                                .buttonStyle(.plain)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 12,
                                        style: .continuous
                                    )
                                )
                                .contextMenu {
                                    Button {
                                        selectedTask = task
                                    } label: {
                                        Label(localizer.string("tasks.view"), systemImage: "eye")
                                    }

                                    Button {
                                        beginEditing(task)
                                    } label: {
                                        Label(localizer.string("tasks.edit"), systemImage: "pencil")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        taskPendingDeletion = task
                                        isDeleteTaskConfirmationOpen = true
                                    } label: {
                                        Label(localizer.string("tasks.delete"), systemImage: "trash")
                                    }
                                }
                                .overlay(alignment: .top) {
                                    if activeDropTarget == .before(task.id) {
                                        insertionIndicator
                                            .offset(y: -5)
                                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                    }
                                }
                                .dropDestination(for: String.self, isEnabled: true) { ids, _ in
                                    handleDrop(ids, before: task.id)
                                }
                                .onDropSessionUpdated { session in
                                    updateDropTarget(.before(task.id), for: session)
                                }
                            }

                            Color.clear
                                .frame(height: activeDropTarget == .end ? 44 : 30)
                                .contentShape(Rectangle())
                                .overlay(alignment: .top) {
                                    if activeDropTarget == .end {
                                        insertionIndicator
                                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                    }
                                }
                                .dropDestination(for: String.self, isEnabled: true) { ids, _ in
                                    handleDrop(ids, before: nil)
                                }
                                .onDropSessionUpdated { session in
                                    updateDropTarget(.end, for: session)
                                }
                        }
                    }
                    .scrollIndicators(.automatic)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
        }
        .padding()
        .frame(width: 280, height: 500)
        .background(columnColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(localizer.string("columns.rename")) {
                isRenameColumnModalOpen = true
            }
            
            Divider()
            
            Button(localizer.string("columns.delete"), role: .destructive) {
                modelContext.delete(column)
            }
        }
        .sheet(isPresented: $isCreateTaskModalOpen) {
            createTaskSheet
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
        }
        .sheet(isPresented: $isRenameColumnModalOpen) {
            renameColumnSheet
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
                .onAppear {
                    renamedColumnTitle = column.title
                }
        }
        .sheet(item: $selectedTask) { task in
            taskDetailSheet(for: task)
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
        }
        .sheet(item: $editingTask) { task in
            editTaskSheet(for: task)
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
                .onAppear {
                    loadTaskForEditing(task)
                }
        }
        .alert(
            localizer.string("tasks.delete.confirmation.title"),
            isPresented: $isDeleteTaskConfirmationOpen,
            presenting: taskPendingDeletion
        ) { task in
            Button(localizer.string("common.cancel"), role: .cancel) {
                taskPendingDeletion = nil
            }

            Button(localizer.string("tasks.delete"), role: .destructive) {
                deleteTask(task)
            }
        } message: { _ in
            Text(verbatim: localizer.string("tasks.delete.confirmation.message"))
        }
        .animation(.snappy(duration: 0.18), value: activeDropTarget)
    }

    private var insertionIndicator: some View {
        Capsule()
            .fill(columnColor)
            .frame(height: 4)
            .shadow(color: columnColor.opacity(0.45), radius: 4)
            .padding(.horizontal, 4)
    }

    private func taskCardLabel(for task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !task.taskTags.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(task.taskTags) { tag in
                            TaskTagChip(tag: tag)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding()
        .contentShape(Rectangle())
    }

    private func handleDrop(_ ids: [String], before targetId: UUID?) {
        guard let idString = ids.first,
              let taskId = UUID(uuidString: idString) else {
            return
        }

        moveTask(
            withId: taskId,
            to: column,
            before: targetId
        )

        activeDropTarget = nil
    }

    private func updateDropTarget(_ target: TaskDropTarget, for session: DropSession) {
        switch session.phase {
        case .entering, .active:
            activeDropTarget = target
        case .exiting, .ended, .dataTransferCompleted:
            if activeDropTarget == target {
                activeDropTarget = nil
            }
        @unknown default:
            if activeDropTarget == target {
                activeDropTarget = nil
            }
        }
    }

    private func beginEditing(_ task: Task) {
        editingTask = task
    }

    private func loadTaskForEditing(_ task: Task) {
        editTaskTitle = task.title
        editTaskDetails = task.details ?? ""
        editTaskHasDueDate = task.dueDate != nil
        editTaskDueDate = task.dueDate ?? Date()
        editTaskTags = task.taskTags
    }

    private func saveEdits(to task: Task) {
        let trimmedTitle = editTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = editTaskDetails.trimmingCharacters(in: .whitespacesAndNewlines)

        task.title = trimmedTitle
        task.details = trimmedDetails.isEmpty ? nil : trimmedDetails
        task.dueDate = editTaskHasDueDate ? editTaskDueDate : nil
        task.taskTags = editTaskTags

        try? modelContext.save()
        editingTask = nil
    }

    private func deleteTask(_ task: Task) {
        let remainingTasks = column.tasks
            .filter { $0.id != task.id }
            .sorted { $0.position < $1.position }

        modelContext.delete(task)

        for (index, remainingTask) in remainingTasks.enumerated() {
            remainingTask.position = Int16(index)
        }

        if selectedTask?.id == task.id {
            selectedTask = nil
        }

        if editingTask?.id == task.id {
            editingTask = nil
        }

        taskPendingDeletion = nil
        try? modelContext.save()
    }
    
    private func moveTask(withId draggedId: UUID, to destination: Column, before targetId: UUID?) {
        if draggedId == targetId {
            return
        }
        
        guard let board = destination.board else {
            return
        }
        
        guard let task = board.columns
            .flatMap(\.tasks)
            .first(where: { $0.id == draggedId }) else {
            return
        }
        
        let source = task.column
        
        var orderedTasks = destination.tasks
            .filter { $0.id != draggedId }
            .sorted { $0.position < $1.position }
        
        let insertionIndex: Int

        if let targetId,
           let targetIndex = orderedTasks.firstIndex(where: { $0.id == targetId }) {
            insertionIndex = targetIndex
        } else {
            insertionIndex = orderedTasks.endIndex
        }
        
        task.column = destination
        
        if source.id != destination.id {
            let remainingSourceTasks = source.tasks
                .filter { $0.id != draggedId }
                .sorted { $0.position < $1.position }

            for (index, sourceTask) in remainingSourceTasks.enumerated() {
                sourceTask.position = Int16(index)
            }
        }
        
        orderedTasks.insert(task, at: insertionIndex)
        
        for (index, task) in orderedTasks.enumerated() {
            task.position = Int16(index)
        }
        
        try? modelContext.save()
    }
    
    private var createTaskSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: localizer.string("tasks.name")).font(.headline)
            TextField(localizer.string("tasks.name.placeholder"), text: $newTaskTitle).frame(width: 300)
            
            Text(verbatim: localizer.string("tasks.details.optional"))
            TextEditor(text: $newTaskDetails)
                .frame(minHeight: 100)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            TaskTagEditor(
                tags: $newTaskTags,
                suggestions: availableBoardTags,
                localizer: localizer
            )
            
            Toggle(localizer.string("tasks.dueDate.toggle"), isOn: $hasDueDate)
            
            if hasDueDate {
                DatePicker(
                    localizer.string("tasks.dueDate"),
                    selection: $newTaskDueDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
            
            HStack {
                Spacer()
                
                Button(localizer.string("common.cancel")) {
                    newTaskTitle = ""
                    newTaskDetails = ""
                    newTaskTags = []
                    isCreateTaskModalOpen = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button(localizer.string("common.create")) {
                    let selectedDate: Date? = hasDueDate ? newTaskDueDate : nil
                    let nextPosition: Int16 = (column.tasks.map(\.position).max() ?? -1) + 1
                    
                    let task = Task(
                        title: newTaskTitle,
                        details: newTaskDetails,
                        tags: TaskTagStorage.encode(newTaskTags),
                        position: nextPosition,
                        column: column,
                        dueDate: selectedDate
                    )
                    modelContext.insert(task)
                    
                    isCreateTaskModalOpen = false
                    newTaskTitle = ""
                    newTaskDetails = ""
                    newTaskTags = []
                    hasDueDate = false
                    newTaskDueDate = Date()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
    }

    private func taskDetailSheet(for task: Task) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    selectedTask = nil
                    beginEditing(task)
                } label: {
                    Label(localizer.string("tasks.edit"), systemImage: "pencil")
                }
            }

            Divider()

            if !task.taskTags.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(task.taskTags) { tag in
                            TaskTagChip(tag: tag)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            if let details = task.details, !details.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: localizer.string("tasks.description"))
                        .font(.headline)
                    Text(details)
                        .textSelection(.enabled)
                }
            } else {
                Text(verbatim: localizer.string("tasks.noDescription"))
                    .foregroundStyle(.secondary)
            }

            if let dueDate = task.dueDate {
                Label {
                    Text(dueDate, format: .dateTime.day().month(.wide).year())
                } icon: {
                    Image(systemName: "calendar")
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button(localizer.string("common.close")) {
                    selectedTask = nil
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(width: 420, height: 280)
    }

    private func editTaskSheet(for task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: localizer.string("tasks.edit.title"))
                .font(.headline)

            TextField(localizer.string("tasks.name"), text: $editTaskTitle)

            Text(verbatim: localizer.string("tasks.details.optional"))
            TextEditor(text: $editTaskDetails)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            TaskTagEditor(
                tags: $editTaskTags,
                suggestions: availableBoardTags,
                localizer: localizer
            )

            Toggle(localizer.string("tasks.dueDate.toggle"), isOn: $editTaskHasDueDate)

            if editTaskHasDueDate {
                DatePicker(
                    localizer.string("tasks.dueDate"),
                    selection: $editTaskDueDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }

            HStack {
                Spacer()

                Button(localizer.string("common.cancel")) {
                    editingTask = nil
                }
                .keyboardShortcut(.cancelAction)

                Button(localizer.string("common.save")) {
                    saveEdits(to: task)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(editTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 380)
    }

    private var renameColumnSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: localizer.string("columns.rename"))
                .font(.headline)

            TextField(
                localizer.string("columns.name.placeholder"),
                text: $renamedColumnTitle
            )
            .frame(width: 300)

            HStack {
                Spacer()

                Button(localizer.string("common.cancel")) {
                    isRenameColumnModalOpen = false
                }
                .keyboardShortcut(.cancelAction)

                Button(localizer.string("common.save")) {
                    column.title = renamedColumnTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    try? modelContext.save()
                    isRenameColumnModalOpen = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renamedColumnTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}
