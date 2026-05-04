import SwiftUI

// MARK: - StudyMode

enum StudyMode: String, CaseIterable {
    case kanjiToMeaning = "Kanji → Meaning"
    case meaningToKanji = "Meaning → Kanji"
}

// MARK: - StudyView (entry point)

struct StudyView: View {
    @EnvironmentObject var store: KanjiStore
    @State private var phase: StudyPhase = .filter

    enum StudyPhase {
        case filter
        case session([Kanji], StudyMode)
        case summary(correct: Int, total: Int)
    }

    var body: some View {
        NavigationView {
            switch phase {
            case .filter:
                FilterSelectionView { kanji, mode in
                    phase = .session(kanji, mode)
                }
            case .session(let kanji, let mode):
                FlashcardView(deck: kanji, mode: mode, onQuit: { phase = .filter }) { correct, total in
                    phase = .summary(correct: correct, total: total)
                }
            case .summary(let correct, let total):
                SessionSummaryView(correct: correct, total: total) {
                    phase = .filter
                }
            }
        }
    }
}

// MARK: - FilterSelectionView

struct FilterSelectionView: View {
    @EnvironmentObject var store: KanjiStore
    var onStart: ([Kanji], StudyMode) -> Void

    @State private var selectedFilters: Set<KanjiFilter> = []
    @State private var allSelected: Bool = true
    @State private var studyMode: StudyMode = .kanjiToMeaning
    @AppStorage("kanjiPerSession") private var kanjiPerSession: Int = 20

    private let jlptLevels = [1, 2, 3, 4, 5]
    private let gradeLevels = [1, 2, 3, 4, 5, 6, 8]
    private let sessionOptions = [20, 30, 40, 50]

    private var pool: [Kanji] {
        allSelected ? store.allKanji : store.kanji(matching: Array(selectedFilters))
    }

    var body: some View {
        Form {
            Section("Study mode") {
                Picker("Mode", selection: $studyMode) {
                    ForEach(StudyMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Kanji per session") {
                Picker("Count", selection: $kanjiPerSession) {
                    ForEach(sessionOptions, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("JLPT Level") {
                filterGrid(filters: jlptLevels.map { KanjiFilter.jlpt($0) },
                           labels: jlptLevels.map { "N\($0)" })
            }

            Section("School Grade") {
                filterGrid(filters: gradeLevels.map { KanjiFilter.grade($0) },
                           labels: gradeLevels.map { $0 == 8 ? "Jinmei" : "G\($0)" })
            }

            Section {
                Button {
                    var deck = pool
                    deck.shuffle()
                    onStart(Array(deck.prefix(kanjiPerSession)), studyMode)
                } label: {
                    HStack {
                        Spacer()
                        Text("Start Session (\(min(kanjiPerSession, pool.count)) kanji)")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(store.allKanji.isEmpty)
            }
        }
        .navigationTitle("Study")
    }

    @ViewBuilder
    private func filterGrid(filters: [KanjiFilter], labels: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All chip
                Button {
                    selectedFilters.removeAll()
                    allSelected = true
                } label: {
                    Text("All")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(allSelected ? Color.accentColor : Color(.systemGray5))
                        .foregroundColor(allSelected ? .white : .primary)
                        .cornerRadius(14)
                }

                ForEach(Array(zip(filters, labels)), id: \.0) { filter, label in
                    let selected = selectedFilters.contains(filter)
                    Button {
                        if selected { selectedFilters.remove(filter) }
                        else {
                            selectedFilters.insert(filter)
                            allSelected = false
                        }
                        if selectedFilters.isEmpty { allSelected = true }
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
        }
    }
}

// MARK: - FlashcardView

struct FlashcardView: View {
    @EnvironmentObject var store: KanjiStore
    let deck: [Kanji]
    let mode: StudyMode
    var onQuit: () -> Void
    var onFinish: (Int, Int) -> Void

    @State private var index = 0
    @State private var options: [Kanji] = []
    @State private var selected: String? = nil  // character for meaningToKanji, meaning string for kanjiToMeaning
    @State private var correctCount = 0
    @State private var showQuitAlert = false
    @State private var srsResults: [(character: String, correct: Bool)] = []

    private var current: Kanji { deck[index] }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(index + 1) / \(deck.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            // Prompt card
            VStack(spacing: 8) {
                if mode == .kanjiToMeaning {
                    Text(current.character)
                        .font(.system(size: 96))
                    if !current.onyomi.isEmpty {
                        Text(current.onyomi.joined(separator: "、"))
                            .font(.title3).foregroundColor(.secondary)
                    }
                    if !current.kunyomi.isEmpty {
                        Text(current.kunyomi.joined(separator: "、"))
                            .font(.title3).foregroundColor(.secondary)
                    }
                } else {
                    Text(current.meanings.prefix(3).joined(separator: ", "))
                        .font(.title2).bold()
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)

            // Answer options
            VStack(spacing: 12) {
                ForEach(options, id: \.character) { option in
                    AnswerButton(state: buttonState(for: option), action: { select(option) }) {
                        if mode == .meaningToKanji {
                            VStack(spacing: 2) {
                                Text(option.character)
                                    .font(.system(.largeTitle))
                                if !option.onyomi.isEmpty {
                                    Text(option.onyomi.joined(separator: "、"))
                                        .font(.caption)
                                }
                                if !option.kunyomi.isEmpty {
                                    Text(option.kunyomi.joined(separator: "、"))
                                        .font(.caption)
                                }
                            }
                        } else {
                            Text(optionLabel(option))
                        }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .navigationTitle("Flashcard")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Quit", role: .destructive) { showQuitAlert = true }
            }
        }
        .alert("Quit Session?", isPresented: $showQuitAlert) {
            Button("Quit", role: .destructive) { onQuit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Progress for this session will not be saved.")
        }
        .onAppear { buildOptions() }
    }

    private func optionLabel(_ kanji: Kanji) -> String {
        if mode == .kanjiToMeaning {
            return kanji.meanings.prefix(3).joined(separator: ", ")
        } else {
            var parts = [kanji.character]
            let readings = (kanji.onyomi + kanji.kunyomi).prefix(2)
            if !readings.isEmpty { parts.append(readings.joined(separator: "、")) }
            return parts.joined(separator: "  ")
        }
    }

    private func buttonState(for option: Kanji) -> AnswerButtonState {
        guard let sel = selected else { return .normal }
        if mode == .kanjiToMeaning {
            let correctMeaning = current.meanings.prefix(3).joined(separator: ", ")
            let optionMeaning = option.meanings.prefix(3).joined(separator: ", ")
            if optionMeaning == sel { return optionMeaning == correctMeaning ? .correct : .wrong }
            if optionMeaning == correctMeaning { return .correct }
        } else {
            if option.character == sel { return option.character == current.character ? .correct : .wrong }
            if option.character == current.character { return .correct }
        }
        return .normal
    }

    private func select(_ option: Kanji) {
        guard selected == nil else { return }
        let isCorrect: Bool
        if mode == .kanjiToMeaning {
            let sel = option.meanings.prefix(3).joined(separator: ", ")
            selected = sel
            isCorrect = sel == current.meanings.prefix(3).joined(separator: ", ")
        } else {
            selected = option.character
            isCorrect = option.character == current.character
        }
        if isCorrect { correctCount += 1 }
        srsResults.append((character: current.character, correct: isCorrect))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { advance() }
    }

    private func advance() {
        if index + 1 < deck.count {
            index += 1
            selected = nil
            buildOptions()
        } else {
            srsResults.forEach { store.updateSRS(kanjiCharacter: $0.character, correct: $0.correct) }
            store.saveSession(kanjiCharacters: deck.map { $0.character }, correct: correctCount)
            onFinish(correctCount, deck.count)
        }
    }

    private func buildOptions() {
        var pool = store.allKanji.filter { $0.character != current.character }
        pool.shuffle()
        var opts = Array(pool.prefix(3))
        opts.append(current)
        opts.shuffle()
        options = opts
    }
}

// MARK: - AnswerButton

enum AnswerButtonState { case normal, correct, wrong }

struct AnswerButton<Label: View>: View {
    let state: AnswerButtonState
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .frame(maxWidth: .infinity)
                .padding()
                .background(background)
                .foregroundColor(foreground)
                .cornerRadius(12)
        }
        .disabled(state != .normal)
    }

    private var background: Color {
        switch state {
        case .normal: return Color(.systemGray5)
        case .correct: return .green
        case .wrong: return .red
        }
    }

    private var foreground: Color {
        state == .normal ? .primary : .white
    }
}

// MARK: - SessionSummaryView

struct SessionSummaryView: View {
    let correct: Int
    let total: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Session Complete!")
                .font(.title).bold()

            Text("\(correct) / \(total)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(correct == total ? .green : .accentColor)

            Text(String(format: "%.0f%% correct", total > 0 ? Double(correct) / Double(total) * 100 : 0))
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            Button("Done") { onDone() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 40)
        }
        .navigationTitle("Summary")
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    StudyView()
        .environmentObject(KanjiStore.shared)
}
