# scripts/build_kanji_json.py

Converts a KANJIDIC2 XML file into `kanji.json` for the Kanji Study iOS app.

## What it does

- Parses KANJIDIC2 XML (gzipped or plain)
- Filters to Jōyō and Jinmei kanji (school grades 1–8)
- Outputs `Kanji Study/kanji.json` in the JishoEntry-compatible format used by `KanjiStore`

Each entry includes: character, on'yomi, kun'yomi, English meanings, JLPT level, school grade, and stroke count.

## Requirements

- Python 3.10+
- KANJIDIC2 file — download from [edrdg.org](https://www.edrdg.org/kanjidic/kanjidic2.xml.gz) or provide a local copy

## Usage

```bash
# Auto-download kanjidic2.xml.gz
python3 build_kanji_json.py

# Use a local file (gzipped or plain XML)
python3 build_kanji_json.py kanjidic2.xml
python3 build_kanji_json.py kanjidic2.xml.gz
```

Output is written to `../Kanji Study/kanji.json`. Re-run this script whenever you want to refresh the bundled kanji data, then rebuild the app.

## Notes

- `kanjidic2.xml` is excluded from version control (see `.gitignore`)
- KANJIDIC2 is distributed under the [EDRDG licence](https://www.edrdg.org/edrdg/licence.html)
