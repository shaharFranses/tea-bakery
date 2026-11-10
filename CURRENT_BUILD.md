# CURRENT_BUILD: tea-bakery (game #4; slug in ./SLUG; user-visible title "Bakery Logic Puzzle"; old title dropped SM 2026-10-25)

The single "what is current" pointer for this game. Every bot reads this before acting (Playbook v1, standing rule 5).
SM owns the State line; `ci/run.sh` fills in "Last CI"; QA fills in Verdict; PO fills in Portal. Times are Asia/Jerusalem.

## State
**State:** active · Stage: 3 thin slice (tutorial + chapters 1-2) re-freeze for TT QA (D0-05 / D0-10 fixes) · Repo: github.com/shaharFranses/tea-bakery (exists; SM pushes and deploys, GB never pushes) · Live: Day-0 `ed57fce` on GitHub Pages since 2026-11-01, served files verified against day0-ed57fce (live index.pck sha256 784edc1c…ab67 re-checked 2026-11-10 07:20) · D0-04 ruled satisfied (SM 2026-11-01 20:55) · Updated: 2026-11-10 07:25 Asia/Jerusalem, TT Godot Build

## Gated build (what QA is testing / has passed)
This file is committed IN the frozen commit, so the commit cannot name its own sha or the export hashes (the export embeds the
commit sha and the pck is not byte-reproducible across exports). The frozen commit is the commit that adds this section
(the day-0 re-freeze commit); its sha, the pck/zip md5+sha256 and the folder are in the gate folder's FREEZE.md.
| Field | Value |
|---|---|
| Commit | see FREEZE.md (the thin-slice re-freeze commit on `main` after thin-4758b99: D0-05 / D0-10 fixes + the step-3 work on main; built from a clean clone) |
| Gate folder | see FREEZE.md (`/workspace/tea-and-tarts-gates/thin-` + the frozen short sha; read-only; contains the frozen Web Release dir + SHA256SUMS, `web-debug/`, the CG zip + .md5/.sha256, `GATE_PACKET.md`, `d023_check.txt`, changelog, slim variant, `FREEZE.md`) |
| Built from | a clean `git clone` checked out at that commit (`ci/run.sh --gate`, slug from ./SLUG = tea-bakery) |
| index.pck sha256 | see FREEZE.md (also SHA256SUMS in the frozen release dir and GATE_PACKET.md; sha256 authoritative, md5 cross-check) |
| Release size | 38.97 MB raw on the stock template (index.wasm 35.38 MB, gz 8.00 MB; index.pck 3.24 MB incl. chapters 1-8 + the 400-board daily pool + the music loop, 8 unused cake sprites excluded; exact bytes in FREEZE.md / SIZE.json) vs 20 MB budget: OVER. Slim variant (PKD slim template, not default): about 25.6 MB raw (wasm 22.05 MB; measured value in FREEZE.md). **20 MB is a HARD gate at Portal-kit exit.** |
| Engine template | **stock** Godot 4.3 web template (default). PKD slim template from Pipeline Ops measured as a variant only |
| SPEC | v1.0.2 (git ce306b9, SPEC.md sha256 f2065400902881b2c96bcb6cb6645f79454ee8e785404b563052a63fd70dd25a): ch5 "Cherry Bakewell"; D-02 phone rules <=3 lines at >=16 px (board >=352, targets >=44); TT-AC-53 note (engine-loader same-origin export-file loads allowed); Art B2 approved |
| QA verdict | 2026-11-01 12:25 Asia/Jerusalem · `ed57fce` · local **PASS** (0 FAIL) · live: see Live QA check row · `/workspace/tea-and-tarts-qa/results/ed57fce/QA_VERDICT.md` |

## Live
| Field | Value |
|---|---|
| Pages URL | https://shaharfranses.github.io/tea-bakery/ (repo shaharFranses/tea-bakery; Pages source GitHub Actions, pages.yml manual-only) |
| Live commit (web/) | ed57fce (frozen day0-ed57fce folder staged byte-for-byte in web/), published 2026-11-01 by SM (main 1d4d1d3, run 41338693610; DEPLOY.md) |
| Live pck sha256 == gated? | **yes**: live index.pck sha256 784edc1cc02abb510afc6360429698b5b1ffb3cb4b34283d97785807054aab67 == day0-ed57fce SHA256SUMS (QA D0-24 2026-11-01; re-fetched by GB 2026-11-10 07:20, match); live SHA256SUMS == staged web/SHA256SUMS |
| Live QA check | Tested 2026-11-01 20:55 Asia/Jerusalem · `ed57fce` live https://shaharfranses.github.io/tea-bakery/ (main 1d4d1d3, run 41338693610) · **PASS** (D0-24, D0-25, AN-53, NAME, D0-02 PASS; D0-04 PASS by SM ruling 2026-11-01 20:55; record finalized 2026-11-10, no retest) · D0-26 phone check: link sent to Shahar 2026-11-01, result not recorded · `/workspace/tea-and-tarts-qa/results/ed57fce-live/QA_VERDICT_LIVE.md` |
| Shahar phone check | not yet |

## Portal
| Field | Value |
|---|---|
| CG zip | see FREEZE.md (file name, md5 and sha256 of the frozen CG zip) |
| Submission | not started |

## Open rulings / interim decisions (broadcast to QA, ART, PO)
- 2026-10-25: working name tea-bakery; no old-title string in source or built output (CI step 7 = QA NAME-01 scanner).
- 2026-10-25: SPEC v0.2 canonical; mobile max 8x8 (44 px), 9x9 desktop only.
- 2026-10-25: responsive layout: wide mode (aspect > 1.0) board left / panel right, 1 logical unit >= 1 CSS px (CI step 6b).
- 2026-10-25: SPEC v1.0.1 locked (99e0b39); config/name "Bakery Logic Puzzle"; slug tea-bakery only in ./SLUG.
- 2026-11-01: SPEC v1.0.2 (ce306b9): step 3 = chapters 3-8, 400-board daily pool, §7.2 end state, Settings Music + Reset progress.
- BLOCKER (size): release 39.16 MB (stock template, wasm 35.38 MB; slim variant 25.80 MB) vs 20 MB; OK for Day-0 (report only, D0-09) but a HARD gate at Portal-kit exit; slim template owned by Pipeline Ops, pending.
- 2026-10-25: CI step 1b = fresh-checkout headless import (fails on Parse Error / SCRIPT ERROR / ERROR: / Unicode parsing error).

## Last CI (auto)
<!-- ci:begin -->
2026-11-10 07:55: CI **PASS** on `f4e00db` · release 38.83 MB (wasm 35.38 MB) · packet `qa/results/ci-f4e00db/GATE_PACKET.md`
<!-- ci:end -->
