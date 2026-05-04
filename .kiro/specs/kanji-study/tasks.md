# Tasks

## Status Legend
- [ ] Not started
- [~] In progress
- [x] Done

---

## Phase 1: Foundation

- [x] Set up Core Data stack (`KanjiStudy.xcdatamodeld`, `KanjiStore`)
- [x] Define `Kanji`, `StudySession`, `StudySettings` models
- [x] Implement `KanjiFilter` (grade / JLPT) and multi-select logic
- [x] Bundle `kanji.json` and seed Core Data on first launch
- [x] Write KANJIDIC2 → `kanji.json` conversion script (`scripts/build_kanji_json.py`)
- [x] Add `grade` and `stroke_count` fields to `JishoEntry` and `KanjiStore.save()`

## Phase 2: Browse

- [x] Build `BrowseView` with kanji list and filter chips
- [x] Build `KanjiDetailView` (character, meanings, on'yomi, kun'yomi, stroke count)

## Phase 3: Study Mode

- [x] Build `FilterSelectionView` (study mode picker + multi-select grade/JLPT + session size)
- [x] Build `FlashcardView` — Kanji → Meaning mode (kanji + readings prompt, 4 meaning options)
- [x] Add Meaning → Kanji mode (meaning prompt, 4 kanji options with character + readings)
- [x] Show up to 3 meanings per option joined by ", "
- [x] Kanji character in answer buttons uses Dynamic Type (`.largeTitle`)
- [x] Reduce flashcard transition delay to 0.2s
- [x] Add Quit button with confirmation alert (returns to filter screen, no saves)
- [x] Defer SRS writes until session fully completed
- [x] Show session summary screen after last card

## Phase 4: SRS / Progress

- [x] Implement SM-2 algorithm (`SRSEngine`)
- [x] Build `ProgressView` (cards due, studied count, upcoming reviews)
- [x] SRS export to timestamped JSON file
- [x] SRS import from JSON file

## Phase 5: Settings

- [x] Kanji loaded count
- [x] SRS Progress export / import
- [ ] Reset SRS progress option

## Backlog / Future

- [ ] Expand `kanji.json` to full Jōyō list (currently filtered to grades 1–8 via KANJIDIC2)
- [ ] Quiz / testing mode
- [ ] iCloud sync
- [ ] Handwriting recognition
- [ ] Widgets (due reviews count)
