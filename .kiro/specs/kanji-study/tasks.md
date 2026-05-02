# Tasks

## Status Legend
- [ ] Not started
- [~] In progress
- [x] Done

---

## Phase 1: Foundation

- [ ] Set up SwiftData stack (ModelContainer, ModelContext)
- [ ] Define `Kanji`, `StudySession`, `StudySettings` models
- [ ] Implement Jisho API service (fetch kanji by JLPT/grade level)
- [ ] Seed local SwiftData store from Jisho API on first launch
- [ ] Implement `KanjiFilter` (grade / JLPT) and multi-select logic

## Phase 2: Browse

- [ ] Build `BrowseView` with kanji list
- [ ] Add filter bar (grade 1–8, JLPT N1–N5 chips, multi-select)
- [ ] Build `KanjiDetailView` (character, meanings, on'yomi, kun'yomi, stroke count)

## Phase 3: Study Mode

- [ ] Build `SettingsView` with kanji-per-session picker (20/30/40/50)
- [ ] Build `FilterSelectionView` (multi-select grade/JLPT before session)
- [ ] Build `FlashcardView` — show kanji + readings, 4 randomized meaning choices
- [ ] Implement answer option generation (1 correct + 3 random from filter set)
- [ ] Show session summary screen after last card

## Phase 4: SRS / Progress

- [ ] Implement SM-2 algorithm to update `srsInterval` and `srsEaseFactor` on answer
- [ ] Build `ProgressView` (stats: cards due, streak, accuracy)
- [ ] Surface due-for-review kanji in study session

## Phase 5: Polish

- [ ] App icon and launch screen
- [ ] Empty states (no kanji match filter, no reviews due)
- [ ] Error handling for Jisho API failures (offline fallback)
- [ ] Accessibility (VoiceOver labels, Dynamic Type)

## Backlog / Future

- [ ] Quiz / testing mode (deferred per requirements)
- [ ] iCloud sync
- [ ] Handwriting recognition
- [ ] Widgets (due reviews count)
