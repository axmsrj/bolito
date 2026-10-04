//
//  BackupService.swift
//  Bolito
//
//  Created by Alex Marcelle on 03/10/26.
//

import Foundation

class BackupService {
    func encode(_ backup: BolitoBackup) throws -> Data {
        let encoder = JSONEncoder()
        
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(backup)
    }
    
    func createBackup(from boards: [Board]) -> BolitoBackup {
        let boardsBackup = boards.map { board in
            BoardBackup(board: board)
        }
        
        return BolitoBackup(
            version: 1,
            exportedAt: Date(),
            boards: boardsBackup
        )
    }
}
