import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var store: KanjiStore

    private var totalStudied: Int { store.studiedCount }
    private var totalKanji: Int { store.allKanji.count }
    private var dueCount: Int { store.dueCount }

    private var accuracy: Double {
        let reviewed = store.allKanji.filter { $0.lastReviewedAt != nil }
        guard !reviewed.isEmpty else { return 0 }
        let avgInterval = Double(reviewed.map { $0.srsInterval }.reduce(0, +)) / Double(reviewed.count)
        // Approximate accuracy from average interval (higher interval = better retention)
        return min(avgInterval / 10.0, 1.0)
    }

    var body: some View {
        NavigationView {
            List {
                Section("Overview") {
                    StatRow(label: "Total Kanji", value: "\(totalKanji)")
                    StatRow(label: "Studied", value: "\(totalStudied)")
                    StatRow(label: "Due for Review", value: "\(dueCount)")
                }

                Section("SRS Breakdown") {
                    let levels = srsLevels()
                    ForEach(levels, id: \.label) { level in
                        HStack {
                            Text(level.label)
                            Spacer()
                            Text("\(level.count)")
                                .foregroundColor(.secondary)
                            Rectangle()
                                .fill(level.color)
                                .frame(width: CGFloat(level.count) / CGFloat(max(totalKanji, 1)) * 80, height: 12)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }

    private struct SRSLevel {
        let label: String
        let count: Int
        let color: Color
    }

    private func srsLevels() -> [SRSLevel] {
        let kanji = store.allKanji
        return [
            SRSLevel(label: "New",      count: kanji.filter { $0.srsInterval == 0 }.count,          color: .gray),
            SRSLevel(label: "Learning", count: kanji.filter { $0.srsInterval > 0 && $0.srsInterval <= 7 }.count,  color: .orange),
            SRSLevel(label: "Review",   count: kanji.filter { $0.srsInterval > 7 && $0.srsInterval <= 21 }.count, color: .blue),
            SRSLevel(label: "Mastered", count: kanji.filter { $0.srsInterval > 21 }.count,           color: .green),
        ]
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProgressView()
        .environmentObject(KanjiStore.shared)
}
