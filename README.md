# Kanji Study

An iOS app for studying Japanese kanji using spaced repetition (SM-2 algorithm).

## Features

- **Browse** — explore kanji filtered by JLPT level (N1–N5) or school grade (1–8)
- **Study** — flashcard sessions with SM-2 spaced repetition scheduling
- **Progress** — track review history and upcoming cards
- **Settings** — configure session size and active filters

## Tech Stack

- SwiftUI + Core Data
- SM-2 spaced repetition engine
- Jisho API for kanji data
- Local `kanji.json` dataset

## Requirements

- iOS 16+
- Xcode 15+

## Getting Started

1. Open `Kanji Study.xcodeproj` in Xcode
2. Select a simulator or device
3. Build and run (`⌘R`)

## Updating Kanji Data

Kanji data is bundled as `Kanji Study/kanji.json`, generated from [KANJIDIC2](https://www.edrdg.org/kanjidic/kanjidic2.xml.gz). To regenerate it:

```bash
cd scripts
python3 build_kanji_json.py              # auto-downloads kanjidic2.xml.gz
python3 build_kanji_json.py kanjidic2.xml  # or use a local file
```

See `scripts/README.md` for details.
