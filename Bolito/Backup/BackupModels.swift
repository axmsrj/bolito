//
//  BackupModels.swift
//  Bolito
//
//  Created by Alex Marcelle on 03/10/26.
//

import Foundation

struct BolitoBackup: Codable {
    let version: Int
    let exportedAt: Date
    let boards: [BoardBackup]
}

struct BoardBackup: Codable {
    let id: UUID
    let title: String
    let columns: [ColumnBackup]
}

extension BoardBackup {
    init(board: Board) {
        id = board.id
        title = board.title
        columns = board.columns
            .sorted { $0.position < $1.position }
            .map { column in
                ColumnBackup(column: column)
            }
    }
}

struct ColumnBackup: Codable {
    let id: UUID
    let title: String
    let color: String?
    let position: Int16
    let tasks: [TaskBackup]
}

extension ColumnBackup {
    init(column: Column) {
        id = column.id
        title = column.title
        color = column.color
        position = column.position
        tasks = column.tasks
            .sorted { $0.position < $1.position }
            .map { task in
                TaskBackup(task: task)
            }
    }
}

struct TaskBackup: Codable {
    let id: UUID
    let title: String
    let details: String
    let tags: [String?]
    let position: Int16
    let dueDate: Date?
}

extension TaskBackup {
    init(task: Task) {
        id = task.id
        title = task.title
        details = task.details!
        tags = task.tags
        position = task.position
        dueDate = task.dueDate
    }
}
