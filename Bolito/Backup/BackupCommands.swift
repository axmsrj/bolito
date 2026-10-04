//
//  BackupCommands.swift
//  Bolito
//
//  Created by Alex Marcelle on 03/10/26.
//

import SwiftUI

struct ExportBackupActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var exportBackupAction: (() -> Void)? {
        get { self[ExportBackupActionKey.self] }
        set { self[ExportBackupActionKey.self] = newValue }
    }
}

struct BackupCommands: Commands {
    @FocusedValue(\.exportBackupAction) private var exportBackup
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    private var localizer: AppLocalizer {
        AppLocalizer(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button {
                exportBackup?()
            } label: {
                Text(verbatim: localizer.string("backup.export"))
            }
            .disabled(exportBackup == nil)
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
    }
}
