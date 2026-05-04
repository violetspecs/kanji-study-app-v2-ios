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
                entity.gradeLevel = Int16(entry.grade ?? 0)
                entity.strokeCount = Int16(entry.stroke_count ?? 0)
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

    // MARK: - SRS Export / Import

    struct SRSRecord: Codable {
        let character: String
        let srsInterval: Int
        let srsEaseFactor: Double
        let nextReviewDate: Date?
        let lastReviewedAt: Date?
    }

    func exportSRS() throws -> URL {
        let records = allKanji.map {
            SRSRecord(character: $0.character,
                      srsInterval: $0.srsInterval,
                      srsEaseFactor: $0.srsEaseFactor,
                      nextReviewDate: $0.nextReviewDate,
                      lastReviewedAt: $0.lastReviewedAt)
        }
        let data = try JSONEncoder().encode(records)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("srs_progress_\(timestamp).json")
        try data.write(to: url)
        return url
    }

    func importSRS(from url: URL) throws {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: url)
        let records = try JSONDecoder().decode([SRSRecord].self, from: data)
        let ctx = container.viewContext
        let request: NSFetchRequest<KanjiEntity> = KanjiEntity.fetchRequest()
        let entities = (try? ctx.fetch(request)) ?? []
        let entityMap = Dictionary(uniqueKeysWithValues: entities.compactMap { e -> (String, KanjiEntity)? in
            guard let c = e.character else { return nil }
            return (c, e)
        })
        for record in records {
            guard let entity = entityMap[record.character] else { continue }
            entity.srsInterval = Int32(record.srsInterval)
            entity.srsEaseFactor = record.srsEaseFactor
            entity.nextReviewDate = record.nextReviewDate
            entity.lastReviewedAt = record.lastReviewedAt
        }
        try ctx.save()
        loadFromStore()
    }
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
