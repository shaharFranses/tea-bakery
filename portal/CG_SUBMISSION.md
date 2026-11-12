# Teacake Lane: CrazyGames Basic Launch submission sheet

Prepared 2026-11-11, rebuilt 2026-11-12 after SPEC v1.6 (no auto-molds), in a Claude Code session at Shahar's request ("go with Teacake Lane and prepare the CrazyGames
package"). **Nothing has been submitted.** The CrazyGames account, the Developer Terms and the upload are Shahar's
(`portal/CG_READINESS.md` §9, steps 1, 2, 9, 11). Field list follows FF's as-seen form (`portal/CG_READINESS.md` §7).

## Build
| Item | Value |
|---|---|
| Build commit | `5e9c33b` (branch `claude/practical-carson-le8dcc`; Godot 4.3 stock web template, `tools/build_web.sh release`) |
| Upload file | `tea-bakery-cg-5e9c33b.zip`, 11,284,572 bytes (`tools/cg_zip.sh`; index.html at the zip root) |
| zip md5 / sha256 | `e81fff83b1a9b5a6d8d1a67dcd5ec8db` / `77a853c38a429f368ea98d0667cd98eaee6a8761375aa2c6478485a415566630` |
| index.pck sha256 | `5a09018e9e817f06910665b27698b53c0fbc7709a872ea3b203f14e64ef0f4d2` |
| Unzipped size | 39.41 MB (wasm 35.38 MB, pck 3.68 MB): under CrazyGames' 50 MB initial-download limit; over the 20 MB mobile-homepage threshold (`portal/CG_READINESS.md` §4) |
| Checked | Unzipped and served locally, Chromium 390x844: page title "Teacake Lane", 0 console errors, 0 requests to other hosts (the CrazyGames SDK loads only on crazygames hosts). GUT 129/129, `spec_assert.py` PASS on this commit |
| **QA** | **NOT RUN on this commit.** The last QA PASS is thin-slice `a4fd2af`, before the level map, stars, per-chapter cakes, card effects, level-break ad slot, the title and the removal of auto-molds (v1.6). Step 6 of the readiness sheet (QA PASS on the gated build, CG iframe-size matrix, Safari/iOS, ads-disabled behaviour) is still open |

## Form fields
| Field | Value |
|---|---|
| Game name | Teacake Lane |
| Game files | `tea-bakery-cg-5e9c33b.zip` |
| Description (one field) | `portal/copy/crazygames.md`, section "Description" |
| Controls | `portal/copy/crazygames.md`, section "Controls" |
| Category | Puzzle (confirm on the live form) |
| Tags (max 5) | Logic, Relaxing, Food, Brain, 2D (alternates: Daily, Cute, Easy) |
| Orientation / mobile | Portrait on phones, landscape re-layout on desktop; mobile friendly: yes |
| Covers | `cover-landscape-1920x1080_5e9c33b.png`, `cover-portrait-800x1200_5e9c33b.png`, `cover-square-800x800_5e9c33b.png` |
| Preview videos | `preview-landscape-1920x1080_5e9c33b.mp4`, `preview-portrait-1080x1620_5e9c33b.mp4` (15.6 s, H.264, 60 fps, no audio stream, faststart, 2.2 / 2.4 MB) |
| PEGI 12 checkbox | Tick |
| AI-tools disclosure | See below: **Shahar must complete this list** |

## AI-tools disclosure (form field)
What this repository shows:
- **Claude (Anthropic), through Claude Code**: game code, spec text, tests, CI, the listing copy, and the scripts that
  composite the covers and capture the preview videos (sessions of 2026-11-03 to 2026-11-11).
- **Art**: `docs/art/LICENSES.md` and `art/LICENSES.md` state that all shipped art is drawn procedurally by in-house
  Python tools, with "no outside images, no AI image generation". The covers are composites of those shipped sprites
  and the game's title font.
- Not visible from the repo: which AI tools the studio's other agents (Art, Growth, Portal Ops, QA, the Godot build
  bot) ran on. Add them before submitting; FF's form listed its tools by name.

## Covers and previews: how they were made
- Launch cover A "Golden tray" (`art/COVERS_PLAN.md`): the real in-game 6x6 board (`portal/tools/render_cover_board.gd`,
  seed 7, berry cake, every cake placed) on a golden tray, tilted 6 degrees, steam over three cakes, raspberry vignette
  background, and the title in DM Serif Display (the game's title font). The title is the only text; no logos, borders
  or badges. Re-run: `portal/tools/make_covers.py`.
- Previews: `portal/tools/preview_demo.gd` in Godot Movie Maker mode (fixed 60 fps): level 23 solved tap by tap, the
  solved card with stars, level 24, then the chapter-end recipe card. Real input path, no speed-up, no cursor, no
  intro logo. `portal/tools/make_previews.sh` prepends the cover (0.6 s hold, 0.3 s cross-fade) and strips audio.
- Differences from Art's plan, for Art to accept or redo: these were composited in this session, not by TT Art; the
  plan's challenger cover B and the thumbnail grid re-test were not done.

## Still open before "Submit" (owner in brackets)
1. QA PASS on the gated build of this code (QA). The build box should produce the gated zip with `ci/run.sh --gate`;
   the zip above is from the same commit but outside the gate.
2. AI-tools list completed (Shahar).
3. Developer Terms, account, exclusivity decision; confirm category and tag picker on the live form (Shahar).
4. Upload the zip to the CrazyGames preview tool and check it boots there (Shahar with SM).
5. Attorney clearance of "Teacake Lane" is advised before any store-app launch (`portal/title-finalists-check.md`:
   desk check only, not legal clearance).
6. Basic Launch runs with ads off; the ad slots (chapter end, level break) only matter at Full Launch.
