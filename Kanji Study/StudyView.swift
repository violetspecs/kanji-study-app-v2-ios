import SwiftUI

// MARK: - StudyView (entry point)

struct StudyView: View {
    @EnvironmentObject var store: KanjiStore
    @State private var phase: StudyPhase = .filter

    enum StudyPhase {
        case filter
        case session([Kanji])
        case summary(correct: Int, total: Int)
    }

    var body: some View {
        NavigationView {
            switch phase {
            case .filter:
                FilterSelectionView { kanji in
                    phase = .session(kanji)
                }
            case .session(let kanji):
                FlashcardView(deck: kanji) { correct, total in
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
    var onStart: ([Kanji]) -> Void

    @State private var selectedFilters: Set<KanjiFilter> = []
    @AppStorage("kanjiPerSession") private var kanjiPerSession: Int = 20

    private let jlptLevels = [1, 2, 3, 4, 5]
    private let gradeLevels = [1, 2, 3, 4, 5, 6, 8]
    private let sessionOptions = [20, 30, 40, 50]

    private var pool: [Kanji] {
        store.kanji(matching: Array(selectedFilters))
    }

    var body: some View {
        Form {
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
                    if deck.isEmpty { deck = store.allKanji }
                    deck.shuffle()
                    onStart(Array(deck.prefix(kanjiPerSession)))
                } label: {
                    HStack {
                        Spacer()
                        Text("Start Session (\(min(kanjiPerSession, max(pool.count, store.allKanji.count))) kanji)")
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
                ForEach(Array(zip(filters, labels)), id: \.0) { filter, label in
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
        }
    }
}

// MARK: - FlashcardView

struct FlashcardView: View {
    @EnvironmentObject var store: KanjiStore
    let deck: [Kanji]
    var onFinish: (Int, Int) -> Void

    @State private var index = 0
    @State private var options: [String] = []
    @State private var selected: String? = nil
    @State private var correctCount = 0

    private var current: Kanji { deck[index] }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(index + 1) / \(deck.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            // Kanji card
            VStack(spacing: 8) {
                Text(current.character)
                    .font(.system(size: 96))

                if !current.onyomi.isEmpty {
                    Text(current.onyomi.joined(separator: "、"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                if !current.kunyomi.isEmpty {
                    Text(current.kunyomi.joined(separator: "、"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)

            // Answer options
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    AnswerButton(
                        text: option,
                        state: buttonState(for: option),
                        action: { select(option) }
                    )
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .navigationTitle("Flashcard")
        .navigationBarBackButtonHidden(true)
        .onAppear { buildOptions() }
    }

    private func buttonState(for option: String) -> AnswerButton.State {
        guard let sel = selected else { return .normal }
        let correct = current.meanings.first ?? ""
        if option == sel {
            return option == correct ? .correct : .wrong
        }
        if option == correct { return .correct }
        return .normal
    }

    private func select(_ option: String) {
        guard selected == nil else { return }
        selected = option
        let isCorrect = option == (current.meanings.first ?? "")
        if isCorrect { correctCount += 1 }
        store.updateSRS(kanjiCharacter: current.character, correct: isCorrect)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            advance()
        }
    }

    private func advance() {
        if index + 1 < deck.count {
            index += 1
            selected = nil
            buildOptions()
        } else {
            store.saveSession(kanjiCharacters: deck.map { $0.character }, correct: correctCount)
            onFinish(correctCount, deck.count)
        }
    }

    private func buildOptions() {
        let correct = current.meanings.first ?? current.character
        var pool = store.allKanji
            .filter { $0.character != current.character }
            .compactMap { $0.meanings.first }
        pool.shuffle()
        var opts = Array(Set(pool.prefix(3)))
        while opts.count < 3 {
            opts.append("—")
        }
        opts.append(correct)
        opts.shuffle()
        options = opts
    }
}

// MARK: - AnswerButton

struct AnswerButton: View {
    enum State { case normal, correct, wrong }
    let text: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
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
