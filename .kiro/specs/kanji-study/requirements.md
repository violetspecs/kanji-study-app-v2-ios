# Requirements

## Overview

Kanji Study is an iOS app for learning and practicing Japanese kanji characters using spaced repetition.

## Functional Requirements

### 1. Kanji Browsing
Browse mode allows the user to select from a list of kanji.
Can be filtered based on Grade level (Grade 1–8, including Jinmei) or JLPT level (N1–N5).
Selecting one displays information about the kanji.

### 2. Study / Flashcard Mode
Users can choose a study mode before starting a session:
- **Kanji → Meaning**: kanji character and readings are shown; user selects the correct English meaning from 4 options
- **Meaning → Kanji**: English meaning is shown; user selects the correct kanji from 4 options (each option displays the kanji in large text with on'yomi and kun'yomi on separate lines below)

Each option displays up to 3 meanings joined by ", " for the Kanji → Meaning mode.
Can filter to show only kanji from a specific grade or JLPT level (multi-select).
An **All** chip is shown at the start of each filter row and is selected by default. If all specific filters are deselected, **All** is automatically re-selected.
Session size is configurable (20, 30, 40, 50 kanji per session) via the filter selection screen.
A **Quit** button is available during a session; tapping it shows a warning that progress will not be saved. Confirming returns to the filter selection screen without saving SRS updates.
SRS updates and session history are only saved when a session is completed in full.

### 3. Progress Tracking
SRS (spaced repetition system) style of progress tracking using the SM-2 algorithm.
Progress view shows cards due, studied count, and upcoming reviews.

### 4. Settings
- Kanji loaded count (read-only)
- **Export SRS Progress**: exports a JSON file named `srs_progress_<timestamp>.json` containing per-kanji SRS state
- **Import SRS Progress**: imports a previously exported JSON file and restores SRS state for matching kanji

### 5. Data Source
Kanji data is sourced from **KANJIDIC2** (Jim Breen), converted to `kanji.json` at build time using `scripts/build_kanji_json.py`.
The script filters to Jōyō and Jinmei kanji (grades 1–8) and outputs entries in the JishoEntry-compatible JSON format.
Each entry includes: character, on'yomi, kun'yomi, English meanings, JLPT level, school grade, and stroke count.

## Non-Functional Requirements

### Performance
Flashcard transition delay is 0.2 seconds after an answer to show feedback before advancing.

### Accessibility
Answer button fonts use Dynamic Type (`.largeTitle` semantic style) to scale with user font size settings.

### Offline Support
The app functions fully offline. Kanji data is bundled as `kanji.json` and seeded into Core Data on first launch.

## Out of Scope
- Quiz / testing mode (deferred)
- iCloud sync
- Handwriting recognition
- Widgets
