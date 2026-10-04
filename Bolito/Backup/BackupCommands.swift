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

struct ImportBackupActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var exportBackupAction: (() -> Void)? {
        get { self[ExportBackupActionKey.self] }
        set { self[ExportBackupActionKey.self] = newValue }
    }


    var importBackupAction: (() -> Void)? {
        get { self[ImportBackupActionKey.self] }
        set { self[ImportBackupActionKey.self] = newValue }
    }
}

struct BackupCommands: Commands {
    @FocusedValue(\.exportBackupAction) private var exportBackup
    @FocusedValue(\.importBackupAction) private var importBackup
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    private var localizer: AppLocalizer {
        AppLocalizer(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button {
                importBackup?()
            } label: {
                Text(verbatim: localizer.string("backup.import"))
            }
            .disabled(importBackup == nil)
            .keyboardShortcut("i", modifiers: [.command, .shift])

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
