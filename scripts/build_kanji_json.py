#!/usr/bin/env python3
"""
Convert KANJIDIC2 (kanjidic2.xml.gz) to kanji.json matching the JishoEntry schema
used by KanjiStore.

Usage:
    python3 build_kanji_json.py                        # downloads kanjidic2.xml.gz automatically
    python3 build_kanji_json.py kanjidic2.xml.gz       # use local file

Output:
    ../Kanji Study/kanji.json
"""

import gzip
import json
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

KANJIDIC2_URL = "http://www.edrdg.org/kanjidic/kanjidic2.xml.gz"
JLPT_MAP_URL = "https://raw.githubusercontent.com/davidluzgouveia/kanji-data/master/kanji.json"
OUTPUT_PATH = Path(__file__).parent.parent / "Kanji Study" / "kanji.json"


def fetch_kanjidic2() -> bytes:
    if len(sys.argv) > 1:
        print(f"Reading {sys.argv[1]}...")
        return Path(sys.argv[1]).read_bytes()
    print(f"Downloading {KANJIDIC2_URL}...")
    with urllib.request.urlopen(KANJIDIC2_URL) as r:
        return r.read()


def fetch_jlpt_map() -> dict[str, int]:
    print(f"Downloading JLPT map from davidluzgouveia/kanji-data...")
    with urllib.request.urlopen(JLPT_MAP_URL) as r:
        data = json.loads(r.read())
    return {char: entry["jlpt_new"] for char, entry in data.items() if "jlpt_new" in entry}


def parse(data: bytes, jlpt_map: dict[str, int]) -> list[dict]:
    xml = gzip.decompress(data) if data[:2] == b'\x1f\x8b' else data
    root = ET.fromstring(xml)
    entries = []

    for char in root.findall("character"):
        literal = char.findtext("literal", "")
        if not literal:
            continue

        misc = char.find("misc")
        if misc is None:
            continue

        # Joyo / jinmei grade filter (grades 1-8; 8 = jinmei)
        grade_el = misc.find("grade")
        grade = int(grade_el.text) if grade_el is not None else None
        if grade is None or grade > 8:
            continue

        stroke_el = misc.find("stroke_count")
        stroke_count = int(stroke_el.text) if stroke_el is not None else 0

        # JLPT level: prefer community map (post-2010), fall back to KANJIDIC2
        jlpt_level = jlpt_map.get(literal)
        if jlpt_level is None:
            jlpt_el = misc.find("jlpt")
            jlpt_level = int(jlpt_el.text) if jlpt_el is not None else None

        # Readings
        reading_meaning = char.find("reading_meaning")
        onyomi, kunyomi = [], []
        meanings = []

        if reading_meaning is not None:
            rmgroup = reading_meaning.find("rmgroup")
            if rmgroup is not None:
                for r in rmgroup.findall("reading"):
                    r_type = r.get("r_type", "")
                    if r_type == "ja_on" and r.text:
                        onyomi.append(r.text)
                    elif r_type == "ja_kun" and r.text:
                        kunyomi.append(r.text)
                for m in rmgroup.findall("meaning"):
                    # Skip non-English meanings (have m_lang attribute)
                    if m.get("m_lang") is None and m.text:
                        meanings.append(m.text)

        if not meanings:
            continue

        # Build JishoEntry-compatible structure
        jlpt_tags = [f"jlpt-n{jlpt_level}"] if jlpt_level else []

        # japanese array: on-readings have no word (word=null), kun-readings have word=literal
        japanese = [{"word": literal, "reading": r} for r in kunyomi]
        japanese += [{"word": None, "reading": r} for r in onyomi]
        if not japanese:
            japanese = [{"word": literal, "reading": None}]

        entries.append({
            "slug": literal,
            "jlpt": jlpt_tags,
            "grade": grade,
            "stroke_count": stroke_count,
            "senses": [{"english_definitions": meanings, "parts_of_speech": ["Noun"]}],
            "japanese": japanese,
            "attribution": None,
        })

    return entries


def main():
    data = fetch_kanjidic2()
    jlpt_map = fetch_jlpt_map()
    entries = parse(data, jlpt_map)
    print(f"Parsed {len(entries)} joyo/jinmei kanji")
    OUTPUT_PATH.write_text(json.dumps(entries, ensure_ascii=False, indent=2))
    print(f"Written to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
