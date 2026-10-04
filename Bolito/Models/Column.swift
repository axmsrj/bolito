//
//  Column.swift
//  Bolito
//
//  Created by Alex Marcelle on 01/10/26.
//

import SwiftData
import Foundation

@Model
final class Column {
    var id: UUID
    var board: Board?
    var title: String
    var color: String?
    var position: Int16
    @Relationship(
        deleteRule: .cascade,
        inverse: \Task.column
    )
    var tasks: [Task] = []
    
    init(board: Board? = nil, title: String, color: String? = nil, position: Int16 = 0) {
        self.id = UUID()
        self.board = board
        self.title = title
        self.color = color
        self.position = position
    }
}
