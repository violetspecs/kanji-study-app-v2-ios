import SwiftUI

struct SettingsView: View {
    @AppStorage("kanjiPerSession") private var kanjiPerSession: Int = 20
    @EnvironmentObject var store: KanjiStore
    @State private var showResetConfirm = false

    private let sessionOptions = [20, 30, 40, 50]

    var body: some View {
        NavigationView {
            Form {
                Section("Study") {
                    Picker("Kanji per session", selection: $kanjiPerSession) {
                        ForEach(sessionOptions, id: \.self) { Text("\($0)").tag($0) }
                    }
                }

                Section("Data") {
                    HStack {
                        Text("Kanji loaded")
                        Spacer()
                        Text("\(store.allKanji.count)").foregroundColor(.secondary)
                    }

                    if store.isSeeding {
                        HStack {
                            SwiftUI.ProgressView()
                            Text("Fetching kanji…").foregroundColor(.secondary)
                        }
                    } else {
                        Button("Refresh Kanji Data") {
                            Task { await store.seedIfNeeded() }
                        }
                    }
                }

                if let error = store.seedError {
                    Section("Error") {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(KanjiStore.shared)
}
