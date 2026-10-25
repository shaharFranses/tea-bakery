# <Game Title>: Art Style Guide (template)
Owner: ART. Lock before gameplay code (Playbook v1 stage 1, Art lock A0). Cite the Player Profile (`/workspace/audience/<game>.md`) in §2 and §6.
Structure lifted from the sudoko_dash style guide (SD Art retro: reuse templates, not SD art).

1. **Folder map**: `assets/art/` (sprites, icons, fonts), `ui/theme/` (generated theme), `docs/art/` (this guide, licences, helper scripts; gdignored)
2. **Palette roles** (hex + role + contrast ratio vs background, ≥4.5:1 for text; CVD check): background, surface, primary, accent, success, error, text, text-muted
3. **Typography**: font (OFL/CC0), sizes (≥12 CSS px at 390x844), weights, outline
4. **Iconography / sprite list**: every entity from the spec, with base-pack coverage (✓ / stand-in / to draw) (DL Art retro)
5. **Per-screen state matrix**: screen × state (empty, in-progress, win, fail, locked, ad, paused) (FF Visuals retro)
6. **Cover / store art**: concept per the Player Profile §5; code-drawn or hand-set lettering (FF/SD Art retros)
7. **Size budget**: art share of the ≤20 MB first download; WebP lossy for large backgrounds
8. **Brand**: PKD intro + `pkd_boot_splash.png` only; never the Godot default icon/splash; the PKD intro is never in covers/previews
