import SwiftUI
import Playgrounds
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Query var boards: [Board]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    
    @State private var isCreateBoardModalOpen = false
    @State private var newBoardName: String = ""
    @State private var selectedBoard: Board?
    @State private var boardBeingRenamed: Board?
    @State private var renamedBoardTitle = ""
    
    private var selectedLocale: Locale {
        AppLanguage(rawValue: appLanguage)?.locale ?? .autoupdatingCurrent
    }

    private var localizer: AppLocalizer {
        AppLocalizer(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }
    
    // backup
    @State private var backupDocument: BackupDocument?
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var pendingBackup: BolitoBackup?
    @State private var isImportConfirmationOpen = false
    @State private var importErrorMessage = ""
    @State private var isImportErrorOpen = false
    private let backupService = BackupService()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedBoard) {
                ForEach(boards) { board in
                    Label(board.title, systemImage: "rectangle.split.3x1")
                    .contextMenu {
                        Button(localizer.string("boards.rename")) {
                            boardBeingRenamed = board
                        }
                        
                        Divider()
                        
                        Button(localizer.string("boards.delete"), role: .destructive) {
                            deleteBoard(board)
                        }
                    }
                    .tag(board)
                }
            }
            .overlay {
                if boards.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text(verbatim: localizer.string("boards.empty.message"))
                        } icon: {
                            Image(systemName: "rectangle.split.3x1")
                        }
                    } description: {
                        Text(verbatim: localizer.string("boards.create.message"))
                    } actions: {
                        Button {
                            isCreateBoardModalOpen = true
                        } label: {
                            Label {
                                Text(verbatim: localizer.string("boards.create"))
                            } icon: {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        isCreateBoardModalOpen = true
                    } label: {
                        Label {
                            Text(verbatim: localizer.string("boards.new.label"))
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            if let selectedBoard {
                BoardView(board: selectedBoard)
            }
            else {
                ContentUnavailableView {
                    Label {
                        Text(verbatim: localizer.string("boards.select.message"))
                    } icon: {
                        Image(systemName: "rectangle.split.3x1")
                    }
                }
            }
        }
        .sheet(isPresented: $isCreateBoardModalOpen) {
            createBoardSheet
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
        }
        .sheet(item: $boardBeingRenamed) { board in
            renameBoardSheet(for: board)
                .environment(\.locale, selectedLocale)
                .id(appLanguage)
                .onAppear {
                    renamedBoardTitle = board.title
                }
        }
        .fileExporter(
            isPresented: $isExportingBackup,
            document: backupDocument,
            contentType: .bolitoBackup,
            defaultFilename: "BolitoBackup.bolito"
        ) { result in
            switch result {
                case .success(let url):
                    print("Backup exported successfully in: ", url)
                case .failure(let error):
                    print("There was an error exporting the backup: ", error)
            }
        }
        .fileImporter(
            isPresented: $isImportingBackup,
            allowedContentTypes: [.bolitoBackup, .json],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .alert(
            localizer.string("backup.import.confirmation.title"),
            isPresented: $isImportConfirmationOpen
        ) {
            Button(localizer.string("backup.import.add")) {
                importPendingBackup(replacingExistingData: false)
            }

            Button(localizer.string("backup.import.replace"), role: .destructive) {
                importPendingBackup(replacingExistingData: true)
            }

            Button(localizer.string("common.cancel"), role: .cancel) {
                pendingBackup = nil
            }
        } message: {
            Text(verbatim: localizer.string("backup.import.confirmation.message"))
        }
        .alert(
            localizer.string("backup.import.error.title"),
            isPresented: $isImportErrorOpen
        ) {
            Button(localizer.string("common.close"), role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .focusedSceneValue(\.exportBackupAction) {
            prepareBackup()
        }
        .focusedSceneValue(\.importBackupAction) {
            isImportingBackup = true
        }
    }
    
    private var createBoardSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: localizer.string("boards.new.title")).font(.headline)
            TextField(localizer.string("boards.new.title.example"), text: $newBoardName).frame(width: 300)
            
            HStack {
                Spacer()
                
                Button(localizer.string("boards.cancel")) {
                    newBoardName = ""
                    isCreateBoardModalOpen = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button(localizer.string("boards.create")) {
                    let board = Board(title: newBoardName)
                    modelContext.insert(board)
                    isCreateBoardModalOpen = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newBoardName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
    }

    private func renameBoardSheet(for board: Board) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: localizer.string("boards.rename.title"))
                .font(.headline)

            TextField(
                localizer.string("boards.rename.placeholder"),
                text: $renamedBoardTitle
            )
            .frame(width: 300)

            HStack {
                Spacer()

                Button(localizer.string("common.cancel")) {
                    boardBeingRenamed = nil
                }
                .keyboardShortcut(.cancelAction)

                Button(localizer.string("common.save")) {
                    board.title = renamedBoardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    try? modelContext.save()
                    boardBeingRenamed = nil
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renamedBoardTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
    
    private func prepareBackup() {
        do {
            let backup = backupService.createBackup(from: boards)
            let data = try backupService.encode(backup)
            
            let document = BackupDocument(data: data)
            backupDocument = document
            
            isExportingBackup = true
        } catch {
            print("There was an error preparing the backup: ", error)
        }
    }

    private func deleteBoard(_ board: Board) {
        if selectedBoard?.id == board.id {
            selectedBoard = nil
        }

        if boardBeingRenamed?.id == board.id {
            boardBeingRenamed = nil
        }

        modelContext.delete(board)
        try? modelContext.save()
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            pendingBackup = try backupService.decode(data)
            isImportConfirmationOpen = true
        } catch {
            showImportError(error)
        }
    }

    private func importPendingBackup(replacingExistingData: Bool) {
        guard let pendingBackup else { return }

        do {
            let importedBoards = backupService.restoreBoards(
                from: pendingBackup,
                preservingIdentifiers: replacingExistingData
            )

            if replacingExistingData {
                selectedBoard = nil
                for board in boards {
                    modelContext.delete(board)
                }
            }

            for board in importedBoards {
                modelContext.insert(board)
            }

            try modelContext.save()
            self.pendingBackup = nil
        } catch {
            modelContext.rollback()
            showImportError(error)
        }
    }

    private func showImportError(_ error: Error) {
        pendingBackup = nil
        importErrorMessage = error.localizedDescription
        isImportErrorOpen = true
    }
}
