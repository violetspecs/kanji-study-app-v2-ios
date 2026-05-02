import Combine
import CoreData
import Foundation

class KanjiStore: ObservableObject {
    static let shared = KanjiStore()

    let container: NSPersistentContainer

    @Published var allKanji: [Kanji] = []
    @Published var isSeeding = false
    @Published var seedError: String?

    init() {
        container = NSPersistentContainer(name: "KanjiStudy")
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData load failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        loadFromStore()
    }

    // MARK: - Read

    func loadFromStore() {
        let request: NSFetchRequest<KanjiEntity> = KanjiEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "character", ascending: true)]
        let entities = (try? container.viewContext.fetch(request)) ?? []
        allKanji = entities.map { $0.toDomain() }
    }

    func kanji(matching filters: [KanjiFilter]) -> [Kanji] {
        guard !filters.isEmpty else { return allKanji }
        return allKanji.filter { k in
            filters.contains { filter in
                switch filter {
                case .jlpt(let n): return k.jlptLevel == n
                case .grade(let n): return k.gradeLevel == n
                }
            }
        }
    }

    // MARK: - Seed

    func seedIfNeeded() async {
        guard allKanji.isEmpty else { return }
        await MainActor.run { isSeeding = true }
        do {
            guard let url = Bundle.main.url(forResource: "kanji", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                throw NSError(domain: "KanjiStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "kanji.json not found in bundle"])
            }
            let entries = try JSONDecoder().decode([JishoEntry].self, from: data)
            await save(entries: entries)
            await MainActor.run {
                loadFromStore()
                isSeeding = false
            }
        } catch {
            await MainActor.run {
                seedError = error.localizedDescription
                isSeeding = false
            }
        }
    }

    private func save(entries: [JishoEntry]) async {
        let ctx = container.newBackgroundContext()
        await ctx.perform {
            // Avoid duplicates
            let existing = (try? ctx.fetch(KanjiEntity.fetchRequest() as NSFetchRequest<KanjiEntity>))?.map { $0.character } ?? []
            let existingSet = Set(existing)

            for entry in entries {
                let word = entry.japanese.first?.word ?? entry.slug
                guard word.count == 1, !existingSet.contains(word) else { continue }

                let entity = KanjiEntity(context: ctx)
                entity.character = word
                entity.meanings = entry.senses.flatMap { $0.english_definitions }.prefix(5).map { $0 } as NSArray
                entity.onyomi = entry.japanese.compactMap { j -> String? in
                    guard let r = j.reading, j.word == nil else { return nil }
                    return r
                } as NSArray
                entity.kunyomi = entry.japanese.compactMap { j -> String? in
                    guard let r = j.reading, j.word != nil else { return nil }
                    return r
                } as NSArray
                entity.jlptLevel = Int16(entry.jlpt.first.flatMap { Int($0.replacingOccurrences(of: "jlpt-n", with: "")) } ?? 0)
                entity.gradeLevel = 0
                entity.strokeCount = 0
                entity.srsInterval = 0
                entity.srsEaseFactor = 2.5
            }
            try? ctx.save()
        }
    }

    // MARK: - SRS Update

    func updateSRS(kanjiCharacter: String, correct: Bool) {
        let ctx = container.viewContext
        let request: NSFetchRequest<KanjiEntity> = KanjiEntity.fetchRequest()
        request.predicate = NSPredicate(format: "character == %@", kanjiCharacter)
        guard let entity = try? ctx.fetch(request).first else { return }

        let result = SRSEngine.update(
            interval: Int(entity.srsInterval),
            easeFactor: entity.srsEaseFactor,
            correct: correct
        )
        entity.srsInterval = Int32(result.interval)
        entity.srsEaseFactor = result.easeFactor
        entity.lastReviewedAt = Date()
        entity.nextReviewDate = Calendar.current.date(byAdding: .day, value: result.interval, to: Date())
        try? ctx.save()

        // Refresh in-memory list
        if let idx = allKanji.firstIndex(where: { $0.character == kanjiCharacter }) {
            allKanji[idx] = entity.toDomain()
        }
    }

    // MARK: - Session Save

    func saveSession(kanjiCharacters: [String], correct: Int) {
        let entity = StudySessionEntity(context: container.viewContext)
        entity.id = UUID()
        entity.date = Date()
        entity.kanjiReviewed = kanjiCharacters as NSArray
        entity.correctCount = Int32(correct)
        entity.totalCount = Int32(kanjiCharacters.count)
        try? container.viewContext.save()
    }

    // MARK: - Progress Stats

    var dueCount: Int {
        allKanji.filter { k in
            guard let next = k.nextReviewDate else { return k.srsInterval > 0 }
            return next <= Date()
        }.count
    }

    var studiedCount: Int { allKanji.filter { $0.lastReviewedAt != nil }.count }
}

// MARK: - CoreData → Domain

extension KanjiEntity {
    func toDomain() -> Kanji {
        Kanji(
            id: character ?? "",
            character: character ?? "",
            meanings: (meanings as? [String]) ?? [],
            onyomi: (onyomi as? [String]) ?? [],
            kunyomi: (kunyomi as? [String]) ?? [],
            jlptLevel: jlptLevel > 0 ? Int(jlptLevel) : nil,
            gradeLevel: gradeLevel > 0 ? Int(gradeLevel) : nil,
            strokeCount: Int(strokeCount),
            srsInterval: Int(srsInterval),
            srsEaseFactor: srsEaseFactor,
            nextReviewDate: nextReviewDate,
            lastReviewedAt: lastReviewedAt
        )
    }
}
