//
//  BackupService.swift
//  Bolito
//
//  Created by Alex Marcelle on 03/10/26.
//

import Foundation

class BackupService {
    enum BackupError: LocalizedError {
        case unsupportedVersion(Int)

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version):
                return "Unsupported backup version: \(version)."
            }
        }
    }

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

    func decode(_ data: Data) throws -> BolitoBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup = try decoder.decode(BolitoBackup.self, from: data)
        guard backup.version == 1 else {
            throw BackupError.unsupportedVersion(backup.version)
        }

        return backup
    }

    func restoreBoards(
        from backup: BolitoBackup,
        preservingIdentifiers: Bool
    ) -> [Board] {
        backup.boards.map { boardBackup in
            let board = Board(title: boardBackup.title)

            if preservingIdentifiers {
                board.id = boardBackup.id
            }

            for columnBackup in boardBackup.columns.sorted(by: { $0.position < $1.position }) {
                let column = Column(
                    board: board,
                    title: columnBackup.title,
                    color: columnBackup.color,
                    position: columnBackup.position
                )

                if preservingIdentifiers {
                    column.id = columnBackup.id
                }

                board.columns.append(column)

                for taskBackup in columnBackup.tasks.sorted(by: { $0.position < $1.position }) {
                    let task = Task(
                        title: taskBackup.title,
                        details: taskBackup.details,
                        tags: taskBackup.tags,
                        position: taskBackup.position,
                        column: column,
                        dueDate: taskBackup.dueDate
                    )

                    if preservingIdentifiers {
                        task.id = taskBackup.id
                    }

                    column.tasks.append(task)
                }
            }

            return board
        }
    }
}
