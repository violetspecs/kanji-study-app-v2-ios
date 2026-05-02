# Design

## Architecture Overview

MVVM architecture with SwiftUI. Data flows from the Jisho API into local SwiftData storage, with a SRS engine managing study scheduling.

```
Views (SwiftUI) → ViewModels → Services → SwiftData / Jisho API
```

## Tech Stack

- Platform: iOS (SwiftUI)
- Language: Swift
- Persistence: SwiftData
- Remote Data: Jisho API (https://jisho.org/api/v1/search/words)
- Architecture: MVVM

## Data Models

### Kanji
```swift
@Model class Kanji {
    var id: String           // e.g. "字"
    var character: String
    var meanings: [String]   // English meanings
    var onyomi: [String]     // katakana readings
    var kunyomi: [String]    // hiragana readings
    var jlptLevel: Int?      // 1–5, nil if unclassified
    var gradeLevel: Int?     // school grade 1–8
    var strokeCount: Int
    var srsInterval: Int     // days until next review
    var srsEaseFactor: Double
    var nextReviewDate: Date?
    var lastReviewedAt: Date?
}
```

### StudySession
```swift
@Model class StudySession {
    var id: UUID
    var date: Date
    var kanjiReviewed: [String]  // kanji character ids
    var correctCount: Int
    var totalCount: Int
    var filterType: FilterType   // .grade / .jlpt / .all
    var filterValue: Int?
}
```

### StudySettings
```swift
struct StudySettings: Codable {
    var kanjiPerSession: Int     // 20 | 30 | 40 | 50, default 20
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
│   ├── FilterSelectionView (multi-select grade/JLPT)
│   └── FlashcardView
│       └── AnswerOptionsView (4 choices)
├── ProgressView
└── SettingsView
    ├── KanjiPerSessionPicker (20/30/40/50)
    └── DefaultFilterSettings
```

## Navigation Flow

- App opens to **BrowseView** (default tab)
- Browse: tap filter chips → list updates → tap kanji → KanjiDetailView (sheet or push)
- Study: tap Study tab → FilterSelectionView → start session → FlashcardView loops through N kanji → summary screen → back to Study tab
- Progress: shows SRS stats and upcoming reviews
- Settings: accessible from tab bar

## Key Design Decisions

- **Jisho API as data source**: Kanji data fetched on first launch and cached locally via SwiftData. No bundled dataset needed.
- **Multi-select filters**: Both grade and JLPT filters can be active simultaneously; the union of matching kanji is used.
- **4-choice quiz format**: Wrong options are randomly sampled from other kanji meanings in the current filter set.
- **SRS on study mode**: Each flashcard answer updates `srsInterval` and `srsEaseFactor` using SM-2 algorithm.
- **Quiz mode deferred**: Stubbed out in navigation but not implemented in v1.
