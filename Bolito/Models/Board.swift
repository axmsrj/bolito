//
//  Board.swift
//  Bolito
//
//  Created by Alex Marcelle on 01/10/26.
//

import SwiftData
import Foundation

@Model
final class Board {
    var id: UUID
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \Column.board)
    var columns: [Column] = []
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.columns = []
    }
}
