//
//  BackupDocument.swift
//  Bolito
//
//  Created by Alex Marcelle on 03/10/26.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let bolitoBackup = UTType(
        exportedAs: "com.axmsrj.Bolito.backup",
        conformingTo: .json
    )
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.bolitoBackup]
    }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.data = fileData
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
