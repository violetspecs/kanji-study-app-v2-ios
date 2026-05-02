import Foundation

class JishoService {
    static let shared = JishoService()
    private let baseURL = "https://jisho.org/api/v1/search/words"

    /// Fetch kanji for a given JLPT level (1–5)
    func fetchKanji(jlpt: Int) async throws -> [JishoEntry] {
        try await fetchPage(keyword: "#jlpt-n\(jlpt)", pages: 3)
    }

    /// Fetch kanji for a given school grade (1–8)
    func fetchKanji(grade: Int) async throws -> [JishoEntry] {
        let keyword = grade <= 6 ? "#grade-\(grade)" : "#jinmeiyou"
        return try await fetchPage(keyword: keyword, pages: 3)
    }

    private func fetchPage(keyword: String, pages: Int) async throws -> [JishoEntry] {
        var all: [JishoEntry] = []
        for page in 1...pages {
            var components = URLComponents(string: baseURL)!
            components.queryItems = [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "page", value: "\(page)")
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let response = try JSONDecoder().decode(JishoResponse.self, from: data)
            // Filter to single-character kanji only
            let kanji = response.data.filter { entry in
                let word = entry.japanese.first?.word ?? entry.slug
                return word.count == 1
            }
            all.append(contentsOf: kanji)
            if response.data.isEmpty { break }
        }
        return all
    }
}
