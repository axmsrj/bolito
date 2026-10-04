//
//  Task.swift
//  Bolito
//
//  Created by Alex Marcelle on 01/10/26.
//

import SwiftData
import Foundation

@Model
final class Task {
    var id: UUID
    var title: String
    var details: String?
    var tags: [String?]
    var position: Int16
    var column: Column
    var dueDate: Date?
    
    init(title: String, details: String? = nil, tags: [String?], position: Int16, column: Column, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.tags = tags
        self.position = position
        self.column = column
        self.dueDate = dueDate
    }
}
