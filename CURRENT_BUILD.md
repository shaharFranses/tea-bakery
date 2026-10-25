# CURRENT_BUILD: Tea & Tarts: Bakery Logic Puzzle (game #4)

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
| Pages URL | https://shaharfranses.github.io/tea-and-tarts/ (not created yet) |
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
- <date>: <ruling>

## Last CI (auto)
<!-- ci:begin -->
2026-10-25 08:20: CI **PASS** on `f0fef91` · release 36.20 MB (wasm 35.38 MB) · packet `qa/results/ci-f0fef91/GATE_PACKET.md` · gated /workspace/pkd-starter-gated/f0fef91
<!-- ci:end -->
