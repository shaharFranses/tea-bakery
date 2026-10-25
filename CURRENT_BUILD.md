# CURRENT_BUILD: tea-bakery (game #4; slug in ./SLUG; user-visible title "Bakery Logic Puzzle"; old title dropped SM 2026-10-25)

The single "what is current" pointer for this game. Every bot reads this before acting (Playbook v1, standing rule 5).
SM owns the State line; `ci/run.sh` fills in "Last CI"; QA fills in Verdict; PO fills in Portal. Times are Asia/Jerusalem.

## State
**State:** active · Stage: 2 Day-0 skeleton, **gated local build frozen for TT QA** (local only; no repo, no Pages, no push) · Updated: 2026-10-25 10:15, TT Godot Build

## Gated build (what QA is testing / has passed)
This file is committed IN the frozen commit, so the commit cannot name its own sha or the export hashes (the export embeds the
commit sha and the pck is not byte-reproducible across exports). The frozen commit is the commit that adds this section
("CURRENT_BUILD: Day-0 gated build ..."); its sha, the pck/zip md5+sha256 and the folder are in the gate folder's FREEZE.md.
| Field | Value |
|---|---|
| Commit | the commit adding this section, on top of 96e2144 (+ cbad78e metrics), branch `main` |
| Gate folder | `/workspace/tea-and-tarts-gates/day0-<sha>/` (read-only): `<sha>/` = frozen Web Release + SHA256SUMS, `web-debug/` (same export run), `tea-bakery-cg-<sha>.zip` (+ .md5/.sha256), `GATE_PACKET.md`, `CHANGELOG_since_b4caec2.md`, `FREEZE.md` |
| Built from | a clean `git clone` checked out at that commit (`ci/run.sh --gate`, slug from ./SLUG = tea-bakery) |
| index.pck sha256 | in `<sha>/SHA256SUMS`, `FREEZE.md` and `GATE_PACKET.md` (sha256 authoritative, md5 cross-check) |
| Release size | **36.48 MB** raw (index.wasm 35.38 MB, gz 8.00 MB; index.pck 0.71 MB) vs 20 MB budget: OVER |
| Engine template | **stock** Godot 4.3 web template. PKD slim template: **pending from Pipeline Ops** (they own it; no slim build here) |
| SPEC | v1.0.1 (git 99e0b39): mold terminology, tap order + cake-first setting, no-op analytics, TT-AC-53 zero game network calls, ads 300 s floor + 180 s gap |
| QA verdict | PENDING, 2026-10-25, QA (`/workspace/tea-and-tarts-qa/run_day0.sh`, see FREEZE.md for the invocation) |

## Live
| Field | Value |
|---|---|
| Pages URL | https://shaharfranses.github.io/tea-bakery/ (repo name TBD, likely tea-bakery; not created yet) |
| Live commit (web/) | `<sha>` |
| Live pck sha256 == gated? | <yes/no, checked date> |
| Live QA check | <PASS/FAIL, date> |
| Shahar phone check | <done date / not yet> |

## Portal
| Field | Value |
|---|---|
| CG zip | `dist/<game>-cg-<sha>.zip`, md5 `<md5>`, <bytes> B |
| Submission | <not started | submitted date | decision> |

## Open rulings / interim decisions (broadcast to QA, ART, PO)
- 2026-10-25: working name tea-bakery; no old-title string in source or built output (CI step 7 = QA NAME-01 scanner).
- 2026-10-25: SPEC v0.2 canonical; mobile max 8x8 (44 px), 9x9 desktop only.
- 2026-10-25: responsive layout: wide mode (aspect > 1.0) board left / panel right, 1 logical unit >= 1 CSS px (CI step 6b).
- 2026-10-25: SPEC v1.0.1 locked (99e0b39); config/name "Bakery Logic Puzzle"; slug tea-bakery only in ./SLUG.
- BLOCKER (size): release 36.48 MB (stock template, wasm 35.38 MB) vs 20 MB target; slim template owned by Pipeline Ops, pending.

## Last CI (auto)
<!-- ci:begin -->
2026-10-25 10:02: CI **PASS** on `96e2144` · release 36.48 MB (wasm 35.38 MB) · packet `qa/results/ci-96e2144/GATE_PACKET.md`
<!-- ci:end -->
