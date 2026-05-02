# Requirements

## Overview

<!-- Brief description of the project and its purpose -->

Kanji Study is an iOS app for learning and practicing Japanese kanji characters.

## Functional Requirements

### 1. Kanji Browsing
<!-- Requirements for browsing/searching kanji -->
Browse mode allows the user to select from a list of kanji
Can be filtered based on Grade level (whether for Grade 1,2,3 etc based on japanese system) or JLPT level
Selecting on one displays the information about the kanji
Information will be retrieved from https://jisho.org API

### 2. Study / Flashcard Mode
<!-- Requirements for study sessions and flashcard functionality -->
Users have the option to set how many kanji per study session (can be changed in a separate settings page)
Can set 20,30,40,50 kanji per session
Can filter to show only kanji from a specific grade or jlpt level
Can select multiple filter options
Study mode displays the Kanji and it's associated readings (on'yomi in katakana script, kunyomi in hiragana script)
Then has 4 options on which meaning is correct (in english)
The options will be randomized based on the meanings of the other Kanji (with one correct answer only)

### 3. Progress Tracking
<!-- Requirements for tracking user progress -->
SRS (spaced repetition system) style of progress tracking

### 4. Quiz / Testing
<!-- Requirements for quizzes and self-assessment -->
For future implementation

### 5. Settings
Different settings for the browse/study/quiz modes are placed here

## Non-Functional Requirements

### Performance
<!-- Performance expectations -->

### Accessibility
<!-- Accessibility requirements -->

### Offline Support
The app must function fully offline after installation.
Kanji data is bundled as a JSON file (`kanji.json`) in the app bundle and seeded into CoreData on first launch — no network request required.
The bundled dataset must cover all **2,136 Jōyō kanji** (常用漢字), including:
- JLPT N5 (~80 kanji)
- JLPT N4 (~170 kanji)
- JLPT N3 (~370 kanji)
- JLPT N2 (~380 kanji)
- JLPT N1 (~1,136 kanji)
Each entry must include: character, on'yomi readings, kun'yomi readings, English meanings, and JLPT level.
The current bundled dataset (~701 kanji) is a placeholder and must be expanded to the full Jōyō list in a future update.

## Out of Scope

<!-- Features explicitly not included in this version -->
