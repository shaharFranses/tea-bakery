# pkd-godot-web-starter

The PKD (Pikeydi) Godot 4.3 browser-game starter. Every new game starts here and must pass the **Day-0 skeleton gate**
(Playbook v1, stage 2, items D0-01..D0-27; see `PLAYBOOK.md` in the Pipeline Ops playbook,
`/workspace/pipeline-ops/playbook/PLAYBOOK.md` on the box) before any gameplay code. It is theme-agnostic: the game name
is the placeholder "Untitled Game", the art is neutral, and the PKD studio intro is the only branding.

## What's in it
| Path | What |
|---|---|
| `project.godot` | 390x844 portrait base, `canvas_items`/`expand`, Compatibility renderer, PKD boot splash on navy `#1E1B3A` |
| `export_presets.cfg` | **generated** by `tools/sync_presets.py`: "Web" (debug + QA hooks) and "Web Release"; single-thread, no extensions |
| `html/head_include.html` | page glue: viewport/safe-area (`PKD_VIEW`), no scroll/zoom, audio gate on tab-hide/blur/ad (`PKD_AUDIO`), CrazyGames SDK v3 glue (`PKD_CG`), PKD loading-screen CSS |
| `pkd_intro/`, `pkd_boot_splash.png` | PKD studio intro drop-in (1.93 s, skippable, ~0.45 MB in the pck). Source: `/workspace/pikeydi-logo/godot/` (INTEGRATION.md). Re-copy if the intro changes |
| `scenes/main.tscn` | stub first scene: intro overlay, safe-area margins, 44px buttons, 12px+ text. Replace with the game |
| `autoload/` | `Dbg` (QA host, toggles, hitlog), `PkdView` (safe-area, CSS px), `Ads` (ad state machine), `Store` (save), `Sfx` (mute arbitration; **never pauses the tree**) |
| `debug/` | QA hooks + ads mock, **debug builds only** (excluded from Web Release) |
| `tests/` | GUT tests (`godot --headless -s addons/gut/gut_cmdln.gd -gexit`) |
| `tools/` | `build_web.sh`, `sync_presets.py`, `freeze_gate.sh`, `publish_web.sh`, `cg_zip.sh`, `serve_unit.sh`, post-export scripts |
| `ci/run.sh` | local CI: tests, export, release audit, boot smoke, console-zero, screenshots, gate packet |
| `web/` | the **frozen, QA-gated** build that Pages serves (committed) |
| `.github/workflows/pages.yml` | deploys `web/` as-is. **It does not re-export** |
| `CURRENT_BUILD.md` | the one "what's current" pointer for the game |

## Day 0 (new game)
1. On GitHub: "Use this template" → `shaharFranses/<game>` (check the spelling; default branch `main`). Settings → Pages → Source: **GitHub Actions**.
2. Clone once to `/workspace/<game>` (one working copy only). Set `config/name` in `project.godot` and the title in CURRENT_BUILD.md.
3. `ci/run.sh` → must PASS (it writes `qa/results/ci-<sha>/GATE_PACKET.md`).
4. `ci/run.sh --gate` on a clean tree → frozen `/workspace/<game>-gated/<sha>/` + `dist/<game>-cg-<sha>.zip`. Hand the gate packet to QA.
5. After QA PASS: `tools/publish_web.sh /workspace/<game>-gated/<sha>` → commit `web/` → push → Pages deploys.
6. `ci/run.sh --live https://shaharfranses.github.io/<game>/` → live pck sha256 must match the gated one. QA live check → CURRENT_BUILD.md.
7. QA checks the live URL in 390x844 touch emulation and gives QA PASS (D0-25). Only then does Shahar open the QA-passed live link on his own phone (D0-26; there is no team phone). Only then does the link go anywhere else. **Nothing reaches Shahar without QA PASS.**

## QA toggles
`?qa=1` hitlog + `window.PKD_QA.dump()` (debug) · `?qa=1&key=value` → `Dbg.toggle("key")` · `?intro=0` / `?audio=0` feature-off (also in release) · F7 dumps state.

## Requirements on the box
Godot 4.3 stable (`godot` on PATH) with export templates; Python 3; Playwright in `$PKD_PY` (default `/workspace/pwvenv/bin/python`) + `/usr/bin/google-chrome`.
Optional slim engine template: `engine/pkd_web_release_slim.zip` (see `engine/README.md`). If present, Web Release uses it; `PKD_STOCK=1` forces stock.

Lifted from: flick-freight (Pages workflow, `?qa=1` pattern), dungeon-loadout (build_web.sh, heap patch, cache-bust, brand), sudoko_dash (presets, head_include, ads/mute/store, touch_scroll, QA dump contract, release audit, GUT).
