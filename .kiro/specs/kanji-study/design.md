# Design

## Architecture Overview

MVVM-lite with SwiftUI + Core Data. Views observe `KanjiStore` (an `ObservableObject`) directly; no separate ViewModel layer.

```
Views (SwiftUI) → KanjiStore (ObservableObject) → Core Data / SRSEngine
```

## Tech Stack

- Platform: iOS 16+ (SwiftUI)
- Language: Swift
- Persistence: Core Data (`KanjiStudy.xcdatamodeld`)
- Data source: Bundled `kanji.json` (generated from KANJIDIC2 via `scripts/build_kanji_json.py`)
- Architecture: MVVM-lite

## Data Models

### Kanji (domain model)
```swift
struct Kanji: Identifiable {
    let id: String           // the character itself
    var character: String
    var meanings: [String]
    var onyomi: [String]
    var kunyomi: [String]
    var jlptLevel: Int?      // 1–5, nil if unclassified
    var gradeLevel: Int?     // 1–8 (8 = jinmei)
    var strokeCount: Int
    var srsInterval: Int
    var srsEaseFactor: Double
    var nextReviewDate: Date?
    var lastReviewedAt: Date?
}
```

### Core Data Entities
- `KanjiEntity` — persists all Kanji fields
- `StudySessionEntity` — records completed sessions (date, kanjiReviewed, correctCount, totalCount)

### SRS Export Record
```swift
struct SRSRecord: Codable {
    let character: String
    let srsInterval: Int
    let srsEaseFactor: Double
    let nextReviewDate: Date?
    let lastReviewedAt: Date?
}
```

### StudySettings
```swift
struct StudySettings: Codable {
    var kanjiPerSession: Int          // 20 | 30 | 40 | 50, default 20
    var selectedFilters: [KanjiFilter]
}

enum KanjiFilter: Codable, Hashable {
    case jlpt(Int)   // 1–5
    case grade(Int)  // 1–8
}
```

## Screen / View Hierarchy

```
ContentView (TabView)
├── BrowseView
│   ├── FilterBar (grade / JLPT chips)
│   └── KanjiDetailView
├── StudyView
│   ├── FilterSelectionView
│   │   ├── StudyMode picker (Kanji→Meaning / Meaning→Kanji)
│   │   ├── KanjiPerSession picker (20/30/40/50)
│   │   └── Grade / JLPT filter chips
│   ├── FlashcardView
│   │   ├── Prompt card (kanji+readings OR meaning text)
│   │   ├── 4× AnswerButton
│   │   └── Quit button (nav bar) → confirmation alert
│   └── SessionSummaryView
├── ProgressView
└── SettingsView
    ├── Kanji loaded (read-only)
    ├── Export SRS Progress
    └── Import SRS Progress
```

## Navigation Flow

- Study tab → `FilterSelectionView` → pick mode + filters → Start Session → `FlashcardView`
- Completing all cards → `SessionSummaryView` (SRS + session saved) → back to filter
- Quitting mid-session → confirmation alert → back to filter (nothing saved)

## Key Design Decisions

- **KANJIDIC2 as data source**: A Python script (`scripts/build_kanji_json.py`) converts KANJIDIC2 XML to `kanji.json` at build time. The app never makes network requests for kanji data.
- **JishoEntry-compatible JSON schema**: `kanji.json` uses the same structure as the previous Jisho API responses, extended with `grade` and `stroke_count` fields, so `KanjiStore` decoding required minimal changes.
- **Two study modes**: `StudyMode` enum drives `FlashcardView` to either show kanji→meaning or meaning→kanji layout. Options are always `[Kanji]` objects; display label is derived via `optionLabel(_:)`.
- **Deferred SRS writes**: SRS updates are buffered in `srsResults` during a session and only flushed to Core Data on full completion. Quitting discards the buffer.
- **Generic `AnswerButton`**: Uses a `@ViewBuilder` label closure so both plain text (kanji→meaning) and structured kanji+readings layouts (meaning→kanji) share the same button chrome.
- **SRS export/import**: Exports only the 5 SRS fields per kanji to a timestamped JSON file. Import matches by character and updates only SRS fields, leaving kanji data intact.
- **Dynamic Type**: Kanji character in answer buttons uses `.system(.largeTitle)` to respect user font size preferences.
