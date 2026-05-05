import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var store: KanjiStore
    @State private var selectedFilters: Set<KanjiFilter> = []
    @State private var selectedKanji: Kanji?
    @State private var searchText: String = ""

    private var displayed: [Kanji] {
        let filtered = store.kanji(matching: Array(selectedFilters))
        guard !searchText.isEmpty else { return filtered }
        let q = searchText.lowercased()
        return filtered.filter {
            $0.character.contains(searchText) ||
            $0.meanings.joined().lowercased().contains(q) ||
            $0.onyomi.joined().contains(searchText) ||
            $0.kunyomi.joined().contains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                FilterBar(selectedFilters: $selectedFilters)
                    .padding(.vertical, 8)
                    .padding(.horizontal)

                if store.isSeeding {
                    Spacer()
                    SwiftUI.ProgressView("Loading kanji…")
                    Spacer()
                } else if displayed.isEmpty {
                    Spacer()
                    Text("No kanji found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(displayed) { kanji in
                        Button {
                            selectedKanji = kanji
                        } label: {
                            HStack {
                                Text(kanji.character)
                                    .font(.title2)
                                    .frame(width: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(kanji.meanings.prefix(2).joined(separator: ", "))
                                        .font(.subheadline)
                                    if let jlpt = kanji.jlptLevel {
                                        Text("N\(jlpt)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Browse")
            .searchable(text: $searchText, prompt: "Search kanji, meaning, reading")
            .sheet(item: $selectedKanji) { kanji in
                KanjiDetailView(kanji: kanji)
            }
            .task {
                await store.seedIfNeeded()
            }
        }
    }
}

// MARK: - FilterBar

struct FilterBar: View {
    @Binding var selectedFilters: Set<KanjiFilter>

    private let jlptLevels = [1, 2, 3, 4, 5]
    private let gradeLevels = [1, 2, 3, 4, 5, 6, 8]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(jlptLevels, id: \.self) { n in
                    chip(filter: .jlpt(n), label: "N\(n)")
                }
                Divider().frame(height: 24)
                ForEach(gradeLevels, id: \.self) { n in
                    chip(filter: .grade(n), label: n == 8 ? "Jinmei" : "G\(n)")
                }
            }
        }
    }

    @ViewBuilder
    private func chip(filter: KanjiFilter, label: String) -> some View {
        let selected = selectedFilters.contains(filter)
        Button {
            if selected { selectedFilters.remove(filter) }
            else { selectedFilters.insert(filter) }
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(14)
        }
    }
}

// MARK: - KanjiDetailView

struct KanjiDetailView: View {
    let kanji: Kanji
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text(kanji.character)
                        .font(.system(size: 80))
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                if !kanji.meanings.isEmpty {
                    Section("Meanings") {
                        ForEach(kanji.meanings, id: \.self) { Text($0) }
                    }
                }

                if !kanji.onyomi.isEmpty {
                    Section("On'yomi") {
                        ForEach(kanji.onyomi, id: \.self) { Text($0) }
                    }
                }

                if !kanji.kunyomi.isEmpty {
                    Section("Kun'yomi") {
                        ForEach(kanji.kunyomi, id: \.self) { Text($0) }
                    }
                }

                Section("Info") {
                    if let jlpt = kanji.jlptLevel {
                        LabeledRow(label: "JLPT", value: "N\(jlpt)")
                    }
                    if let grade = kanji.gradeLevel {
                        LabeledRow(label: "Grade", value: "\(grade)")
                    }
                    if kanji.strokeCount > 0 {
                        LabeledRow(label: "Strokes", value: "\(kanji.strokeCount)")
                    }
                    LabeledRow(label: "SRS Interval", value: "\(kanji.srsInterval) days")
                }
            }
            .navigationTitle(kanji.character)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    BrowseView()
        .environmentObject(KanjiStore.shared)
}
