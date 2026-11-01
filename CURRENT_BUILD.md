# CURRENT_BUILD: tea-bakery (game #4; slug in ./SLUG; user-visible title "Bakery Logic Puzzle"; old title dropped SM 2026-10-25)

The single "what is current" pointer for this game. Every bot reads this before acting (Playbook v1, standing rule 5).
SM owns the State line; `ci/run.sh` fills in "Last CI"; QA fills in Verdict; PO fills in Portal. Times are Asia/Jerusalem.

## State
**State:** active · Stage: 2 Day-0 skeleton, **gated local build frozen for TT QA** (local only; no repo, no Pages, no push) · Updated: 2026-11-01 12:05 Asia/Jerusalem, TT Godot Build (Day-0 re-freeze: D0-05, D0-23)

## Gated build (what QA is testing / has passed)
This file is committed IN the frozen commit, so the commit cannot name its own sha or the export hashes (the export embeds the
commit sha and the pck is not byte-reproducible across exports). The frozen commit is the commit that adds this section
(the day-0 re-freeze commit); its sha, the pck/zip md5+sha256 and the folder are in the gate folder's FREEZE.md.
| Field | Value |
|---|---|
| Commit | see FREEZE.md (the day-0 re-freeze commit on branch `day0-fix`, after 457c753; built from a clean clone) |
| Gate folder | see FREEZE.md (`/workspace/tea-and-tarts-gates/day0-` + the frozen short sha; read-only; contains the frozen Web Release dir + SHA256SUMS, `web-debug/`, the CG zip + .md5/.sha256, `GATE_PACKET.md`, changelog, `FREEZE.md`) |
| Built from | a clean `git clone` checked out at that commit (`ci/run.sh --gate`, slug from ./SLUG = tea-bakery) |
| index.pck sha256 | see FREEZE.md (also SHA256SUMS in the frozen release dir and GATE_PACKET.md; sha256 authoritative, md5 cross-check) |
| Release size | 39.16 MB raw on the stock template (index.wasm 35.38 MB, gz 8.00 MB; index.pck 3.39 MB; exact bytes in FREEZE.md / SIZE.json) vs 20 MB budget: OVER. Slim variant (PKD slim template, not default): 25.80 MB raw (wasm 22.05 MB). Day-0 D0-09 only requires reporting it. **20 MB is a HARD gate at Portal-kit exit.** |
| Engine template | **stock** Godot 4.3 web template (default). PKD slim template from Pipeline Ops measured as a variant only |
| SPEC | v1.0.1 (git 99e0b39): mold terminology, tap order + cake-first setting, no-op analytics, TT-AC-53 zero game network calls, ads 300 s floor + 180 s gap |
| QA verdict | 2026-11-01 12:10 Asia/Jerusalem · `457c753` (code `6cf5b9b`) · local **FAIL**: D0-05, D0-23 · live not run · `/workspace/tea-and-tarts-qa/results/457c753/QA_VERDICT.md` |

## Live
| Field | Value |
|---|---|
| Pages URL | https://shaharfranses.github.io/tea-bakery/ (repo name TBD, likely tea-bakery; not created yet) |
| Live commit (web/) | none yet (not published) |
| Live pck sha256 == gated? | not checked yet (not published); compare against the gated index.pck sha256, see FREEZE.md |
| Live QA check | not run yet |
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
- BLOCKER (size): release 39.16 MB (stock template, wasm 35.38 MB; slim variant 25.80 MB) vs 20 MB; OK for Day-0 (report only, D0-09) but a HARD gate at Portal-kit exit; slim template owned by Pipeline Ops, pending.
- 2026-10-25: CI step 1b = fresh-checkout headless import (fails on Parse Error / SCRIPT ERROR / ERROR: / Unicode parsing error).

## Last CI (auto)
<!-- ci:begin -->
2026-11-01 12:06: CI **PASS** on `6d35a6d` · release 39.16 MB (wasm 35.38 MB) · packet `qa/results/ci-6d35a6d/GATE_PACKET.md`
<!-- ci:end -->
