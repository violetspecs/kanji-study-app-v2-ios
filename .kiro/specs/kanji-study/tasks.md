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
- [x] Add search bar (filters by character, meaning, on'yomi, kun'yomi)
- [x] Build `KanjiDetailView` (character, meanings, on'yomi, kun'yomi, stroke count)

## Phase 3: Study Mode

- [x] Build `FilterSelectionView` (study mode picker + multi-select grade/JLPT + session size)
- [x] Add "All" chip to filter rows (selected by default; auto-reverts when all filters deselected)
- [x] Build `FlashcardView` — Kanji → Meaning mode (kanji + readings prompt, 4 meaning options)
- [x] Draw wrong options from full filtered pool (not session deck) for accurate level-matched distractors
- [x] Add Meaning → Kanji mode (meaning prompt, 4 kanji options with character + readings)
- [x] Fix text overflow in meaning→kanji mode (minimumScaleFactor + lineLimit on prompt and buttons)
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
- [x] Hide readings during study toggle (applies to prompt card and answer buttons)
- [x] SRS Progress export / import
- [ ] Reset SRS progress option

## Backlog / Future

- [ ] Expand `kanji.json` to full Jōyō list (currently filtered to grades 1–8 via KANJIDIC2)
- [ ] Quiz / testing mode
- [ ] iCloud sync
- [ ] Handwriting recognition
- [ ] Widgets (due reviews count)
