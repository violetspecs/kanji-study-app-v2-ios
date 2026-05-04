import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("kanjiPerSession") private var kanjiPerSession: Int = 20
    @EnvironmentObject var store: KanjiStore
    @State private var showResetConfirm = false
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var importError: String?

    private let sessionOptions = [20, 30, 40, 50]

    var body: some View {
        NavigationView {
            Form {                Section("Data") {
                    HStack {
                        Text("Kanji loaded")
                        Spacer()
                        Text("\(store.allKanji.count)").foregroundColor(.secondary)
                    }
                }

                Section("SRS Progress") {
                    Button("Export Progress") {
                        if let url = try? store.exportSRS() {
                            exportURL = url
                            showExporter = true
                        }
                    }
                    Button("Import Progress") {
                        showImporter = true
                    }
                    if let error = importError {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                if let error = store.seedError {
                    Section("Error") {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $showExporter,
                document: exportURL.map { JSONFile(url: $0) },
                contentType: .json,
                defaultFilename: exportURL?.deletingPathExtension().lastPathComponent ?? "srs_progress"
            ) { _ in }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    do {
                        try store.importSRS(from: url)
                        importError = nil
                    } catch {
                        importError = error.localizedDescription
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
        }
    }
}

struct JSONFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let url: URL

    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws { url = FileManager.default.temporaryDirectory }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
}

#Preview {
    SettingsView()
        .environmentObject(KanjiStore.shared)
}
