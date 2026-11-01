# DEPLOY: frozen-folder GitHub Pages path (tea-bakery)

Rule: Pages serves ONLY a QA-gated freeze, byte-for-byte. Nothing is built or exported for a deploy, and nothing deploys
on push: `.github/workflows/pages.yml` runs only when started by hand (workflow_dispatch). There is no build-from-main
deploy workflow.

## First deploy: Day-0 build ed57fce (QA PASS 2026-11-01)
- Gate folder: `/workspace/tea-and-tarts-gates/day0-ed57fce` (release dir `ed57fce/`)
- index.pck sha256: `784edc1cc02abb510afc6360429698b5b1ffb3cb4b34283d97785807054aab67`
- Already staged and committed in `web/` (see `web/FROZEN_FROM.txt`); verified locally with
  `tools/verify_frozen_snapshot.sh web 784edc1cc02abb510afc6360429698b5b1ffb3cb4b34283d97785807054aab67` (PASS, 8 files).

## Steps once the repo exists (repo creation and push are owner actions, not done by the build bot)
1. Repo settings, Pages: Source = "GitHub Actions" (once).
2. Push main (it already contains the staged `web/`).
3. Actions, "deploy frozen snapshot (web/) to GitHub Pages", Run workflow, input `expected_pck_sha256` =
   `784edc1cc02abb510afc6360429698b5b1ffb3cb4b34283d97785807054aab67`.
   CLI: `gh workflow run pages.yml -f expected_pck_sha256=784edc1cc02abb510afc6360429698b5b1ffb3cb4b34283d97785807054aab67`
4. The workflow verifies every file in `web/` against `web/SHA256SUMS` (fails on any mismatch, missing or extra file, or
   a different pck), uploads `web/` with actions/upload-pages-artifact, deploys with actions/deploy-pages, then runs
   `tools/verify_served.sh` against the Pages URL.
5. From the box, re-check the live site: `tools/verify_served.sh https://shaharfranses.github.io/tea-bakery/ web`
   (expects "SERVED == FROZEN"), then record it in CURRENT_BUILD.md "Live".

## Later deploys (a newer QA-passed freeze)
1. `tools/stage_frozen_deploy.sh /workspace/tea-and-tarts-gates/FOLDER` (FOLDER = the QA-passed gate folder name).
   It checks the folder against its own SHA256SUMS, copies exactly the listed files plus SHA256SUMS into `web/`, writes
   `web/FROZEN_FROM.txt`, and re-verifies.
2. `git add -f web && git commit`, push, then run the workflow with that freeze's pck sha256 (from its FREEZE.md).

CI preflight runs `tools/verify_frozen_snapshot.sh web` whenever `web/SHA256SUMS` exists, so a staged snapshot can
never be edited by accident.
