# art/ licence and provenance ledger (art-direction tooling, not shipped)
Shipped assets go in `docs/art/LICENSES.md` (the project ledger). This file covers `art/` only.

| File / folder | Origin | Author | Licence | Notes |
|---|---|---|---|---|
| `tools/fonts/AtkinsonHyperlegibleNext-{Regular,Medium,Bold}.ttf` | Copied 2026-10-25 from Sudoku Dash `assets/art/fonts/` at commit `a795a1a` (via `git show`), originally https://github.com/googlefonts/atkinson-hyperlegible-next (google/fonts `ofl/atkinsonhyperlegiblenext`) | The Atkinson Hyperlegible Next Project Authors | SIL OFL 1.1, no Reserved Font Name | These are SD's static Latin-subset instances (wght 400/500/700, fontTools). Known quirk: all three carry the name-table subfamily "Regular" even though the outlines are different weights, so load them by file, not by family and style |
| `tools/fonts/OFL-AtkinsonHyperlegibleNext.txt` | Same commit, `assets/art/fonts/OFL-AtkinsonHyperlegibleNext.txt` | — | SIL OFL 1.1 text | Must travel with the fonts |
| `tools/gen_palette.py` | Adapted from Sudoku Dash `tools/art/gen_palette.py` @ `a795a1a` | PKD (in-house) | PKD proprietary | Rewritten to generate the whole `ArtPalette` .gd and palette.json from `ttcolor.py` |
| `tools/ttcolor.py`: `CONTRAST_RULES` / `contrast_table()` | Structure adapted from Sudoku Dash `docs/art/tools/palette.py` @ `a795a1a` (role-based PASS/FAIL table) | PKD (in-house) | PKD proprietary | Our own rules and colours. The CVD (Machado 2009) and CIEDE2000 code is original to tea-bakery |
| Everything else in `tools/*.py` and all PNGs in `art/` | Original, drawn procedurally | PKD (TT Art) | PKD proprietary | No outside images, no AI image generation |
| Fonts for rendering: DM Serif Display, Lexend, Dancing Script | System copies (`/usr/share/fonts/.../google/`) | Their authors | SIL OFL 1.1 | **Lexend and DM Serif Display now ship** in `assets/fonts/` (rows in `docs/art/LICENSES.md`). Dancing Script is mock-only and does not ship |
| `covers/concept_*.jpg`, `tools/cover_concepts.py`, `tools/export_p*.py`, `tools/gen_manifest.py` | Original, built from our own shipped sprites | PKD (TT Art) | PKD proprietary | Cover concepts are for the A/B discussion only, not final covers |
| `sd_side_by_side.png` (left half) | Sudoku Dash `sd_art/theme_preview.png` | PKD (SD Art) | PKD proprietary | Internal comparison only; never use in tea-bakery store assets |
