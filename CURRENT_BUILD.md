# CURRENT_BUILD: tea-bakery (game #4, working name; title TBD, old title dropped SM 2026-10-25)

The single "what is current" pointer for this game. Every bot reads this before acting (Playbook v1, standing rule 5).
SM owns the State line; `ci/run.sh` fills in "Last CI"; QA fills in Verdict; PO fills in Portal. Times are Asia/Jerusalem.

## State
**State:** active · Stage: 2 Day-0 skeleton (local only; no repo, no Pages yet; QA not run) · Updated: 2026-10-25 08:45, TT Godot Build

## Gated build (what QA is testing / has passed)
| Field | Value |
|---|---|
| Commit | `<sha>` (branch `<branch>`) |
| Gated dir | `/workspace/<game>-gated/<sha>/` (SHA256SUMS inside) |
| Local port | `:<port>` (tools/serve_unit.sh) |
| index.pck sha256 | `<first 16>` |
| index.wasm size / gz | <MB> / <MB>; engine template: <stock | pkd slim> |
| Gate packet | `qa/results/ci-<sha>/GATE_PACKET.md` |
| QA verdict | <PENDING | PASS | FAIL: reason>, <date>, QA |

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
- BLOCKER: release ~36 MB (stock template, wasm ~35 MB) vs 20 MB target; Pipeline Ops slim template build OOM'd (engine/build_slim.log), pending.

## Last CI (auto)
<!-- ci:begin -->
2026-10-25 08:20: CI **PASS** on `f0fef91` · release 36.20 MB (wasm 35.38 MB) · packet `qa/results/ci-f0fef91/GATE_PACKET.md` · gated /workspace/pkd-starter-gated/f0fef91
<!-- ci:end -->
