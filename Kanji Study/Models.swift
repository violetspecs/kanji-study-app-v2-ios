import Foundation

// MARK: - Filter

enum KanjiFilter: Hashable, Codable {
    case jlpt(Int)   // 1–5
    case grade(Int)  // 1–8

    var displayName: String {
        switch self {
        case .jlpt(let n): return "N\(n)"
        case .grade(let n): return "Grade \(n)"
        }
    }
}

// MARK: - Settings

struct StudySettings: Codable {
    var kanjiPerSession: Int = 20
    var selectedFilters: [KanjiFilter] = []

    static let kanjiPerSessionOptions = [20, 30, 40, 50]

    static func load() -> StudySettings {
        guard let data = UserDefaults.standard.data(forKey: "StudySettings"),
              let settings = try? JSONDecoder().decode(StudySettings.self, from: data)
        else { return StudySettings() }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "StudySettings")
        }
    }
}

// MARK: - Domain Model

struct Kanji: Identifiable {
    let id: String          // the character itself
    var character: String
    var meanings: [String]
    var onyomi: [String]
    var kunyomi: [String]
    var jlptLevel: Int?
    var gradeLevel: Int?
    var strokeCount: Int
    var srsInterval: Int        // days
    var srsEaseFactor: Double   // SM-2 ease factor
    var nextReviewDate: Date?
    var lastReviewedAt: Date?
}

// MARK: - Jisho API Response

struct JishoResponse: Decodable {
    let data: [JishoEntry]
}

struct JishoEntry: Decodable {
    let slug: String
    let jlpt: [String]
    let grade: Int?
    let stroke_count: Int?
    let senses: [JishoSense]
    let japanese: [JishoJapanese]
    let attribution: JishoAttribution?

    struct JishoSense: Decodable {
        let english_definitions: [String]
        let parts_of_speech: [String]
    }

    struct JishoJapanese: Decodable {
        let word: String?
        let reading: String?
    }

    struct JishoAttribution: Decodable {
        let jmdict: Bool?
        let jmnedict: Bool?
        let dbpedia: AnyCodable?
    }
}

// Helper to decode fields that can be Bool or String
struct AnyCodable: Decodable {
    init(from decoder: Decoder) throws {
        _ = try? decoder.singleValueContainer()
    }
}
