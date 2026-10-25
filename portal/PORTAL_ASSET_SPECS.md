# tea-bakery: portal asset specs (covers, thumbnails, previews, icons, screenshots)
Prepared 2026-10-25, ~08:45–09:10 (Asia/Jerusalem), by TT Portal Ops for TT Art. Research only; no sign-ins.
Working name **tea-bakery**; the title is pending (finalists in `title-finalists-check.md`). Context: `art/ART_DIRECTION.md` (v1 proposal, Option B "Crisp Pastry Flat", no title in any image).

**Precedence:** FF Portal Ops' as-seen CrazyGames form wins where it differs from CG's docs (per the brief). ⚠️ = unverified (needs a logged-in portal form or isn't published publicly).

## Sources
- **[FF-PB]** `/home/box/portal-ops/portals/CG_BASIC_PLAYBOOK.md` (lines 7, 11–12, 20)
- **[FF-SUB]** `/home/box/portal-ops/games/flick-freight/submission/CRAZYGAMES_BASIC_SUBMISSION.md`, AS SUBMITTED (lines 30–34, 41, 52)
- **[REQ]** `/home/box/portal-ops/portals/REQUIREMENTS.md` (line 28 GD thumbs; Poki/GD sections), dated 2026-09-18
- **[CG-COV]** https://docs.crazygames.com/requirements/game-covers/ (fetched 2026-10-25)
- **[CG-QUAL]** https://docs.crazygames.com/requirements/quality/ (see `cg-requirements.md`)
- **[POKI-THUMB]** https://developers.poki.com/guide/game-thumbnail (fetched 2026-10-25)
- **[POKI-PAGE]** https://developers.poki.com/guide/your-game-page (Animated thumbnails section, fetched 2026-10-25)
- **[POKI-REQ]** https://developers.poki.com/guide/requirements-quality (same text at https://sdk.poki.com/new-requirements)
- **[POKI-SHARE]** https://developers.poki.com/guide/share (submission form)
- **[GD-DEV]** https://static.gamedistribution.com/developer/developers-guidelines.html §5.1 Thumbnails
- **[GD-DES]** https://static.gamedistribution.com/developer/design-guidelines.html (Minimum requirements, 200×120 rules, Immediate declines)
- **[GD-FAQ]** https://gamedistribution.com/developers/faq/general-questions/what-are-the-requirements-for-the-thumbnails/
- **[CGR]** `portal/CG_READINESS.md` (guardrails 3–4) · **[TM]** `portal/trademark-check.md`

---

## 1. CrazyGames (first lane)
### Covers: 3 required
| Spec | Value | Source |
|---|---|---|
| Landscape | **16:9, 1920×1080** | [CG-COV] "Mandatory sizes"; [FF-SUB] l.30 |
| Portrait | **2:3, 800×1200** | [CG-COV]; [FF-SUB] l.31 |
| Square | **1:1, 800×800** | [CG-COV]; [FF-SUB] l.32 |
| Format | **PNG** (FF uploaded PNG and it was accepted). The docs name no format. ⚠️ Whether JPG/WebP is accepted wasn't checked (form) | [FF-PB] l.11; [FF-SUB] l.30–32 |
| Max file size | **Not published.** ⚠️ The form limit wasn't seen | [CG-COV] (none stated) |
| Safe zones | **None published.** CG crops and positions covers itself on its tiles; keep key art and any title away from the edges (my recommendation, not a CG rule) | [CG-COV] (none stated) |
| Consistency | All three must "feature consistent visuals and aesthetics" | [CG-COV] |
| **Text** | **"Don't write anything else other than your game's title"** (no New / Updated / Play / Play now). Putting the title on the cover is **recommended, not mandatory** ("Put the name of your game directly on the cover" is under *Guidelines*, not *Restrictions*). FF's wording "title only" means *only the title is allowed*, not that it's required | [CG-COV] Restrictions + Guidelines; [FF-PB] l.11 |
| Logos / icons | **No icons or store logos.** FF: "no borders/logos". Treat a studio (PKD) logo as not allowed too: it's neither the title nor permitted | [CG-COV]; [FF-PB] l.11 |
| Other rules | No borders · no copyrighted visuals · no blurry or pixelated art · not just a screenshot ("try to be more creative") · keep it simple and uncluttered | [CG-COV] |
| Must match the build | Covers must match the **current in-game art** (FF redid covers on submit day). Re-check against the exact build commit and stamp each asset with that commit | [FF-PB] l.11, l.20 |
| Updates | Update covers occasionally, e.g. with content or seasonal updates, but not too often | [CG-COV] |

### Preview videos: 2
| Spec | Value | Source |
|---|---|---|
| Required? | Docs: "mandatory". **FF (wins): optional for Basic Launch but recommended**, since they drive homepage CTR. → Make both | [CG-COV]; [FF-PB] l.12; [FF-SUB] l.41 |
| Landscape | **1080p 16:9 = 1920×1080** | [CG-COV]; [FF-PB] l.12 |
| Portrait | **"1080p, 2:3"**. FF shipped **1080×1620** and it was accepted. ⚠️ CG doesn't say whether "1080p" means 1080 wide or 1080 tall (1080×1620 is the FF-proven reading) | [CG-COV]; [FF-PB] l.12; [FF-SUB] l.34 |
| Length | **15–20 s**; longer is cut at 20 s. FF's was 16.1 s | [CG-COV]; [FF-PB] l.12 |
| Max size | **50 MB** (FF's were 1.0 and 1.5 MB) | [CG-COV]; [FF-PB] l.12 |
| Audio | **No sound.** FF shipped with **no audio stream at all** | [CG-COV]; [FF-PB] l.12 |
| Format | **MP4, H.264, faststart** (FF, accepted). The docs name no codec or container. ⚠️ Other formats not checked | [FF-PB] l.12 |
| Opening frame | **Must open on the static cover** (seamless hover transition) | [CG-COV]; [FF-PB] l.12 |
| Avoid | Black screen or logo intro · black bars · default mouse cursor · "Play Now" or promo text · app or social icons · **fast-forwarding** (CG speeds it up slightly itself). Animation is allowed if it represents gameplay and isn't misleading | [CG-COV] |
| Frame rate | Not published ⚠️ | — |

### Icons / screenshots / thumbnails
- **No separate icon or screenshot upload** in FF's as-seen form: "3 covers · 2 preview videos" are the only media [FF-PB] l.7. CG's FAQ word "thumbnails" refers to the covers (see `cg-requirements.md`). The gameplay video doubles as the hover thumbnail [CG-COV].

## 2. Poki (second lane; curated)
### Static thumbnail: 1 required
| Spec | Value | Source |
|---|---|---|
| Size / ratio | **Full-bleed 1:1 square, at least 628×628** | [POKI-THUMB] |
| Required? | **Yes**: "required to start a player fit test"; static + animated both required for global release | [POKI-THUMB]; [POKI-REQ] Platform integration |
| Format / max size | **Not published** ⚠️ (Poki for Developers upload needs a login) | — |
| Safe zones | No numeric zone. **Poki applies rounded corners itself**, so keep key detail off the corners. It must read at small tile sizes | [POKI-THUMB] |
| **Text** | **"Avoid text. Skip titles and other text"**: Poki's tests show text-free thumbnails perform better | [POKI-THUMB] |
| Logos | Not addressed for thumbnails. The "avoid text" rule makes a wordmark undesirable. Studio logo is only "welcome on the loading screen" (in-game) | [POKI-THUMB]; [POKI-REQ] |
| Other rules | No borders, padding or letterboxing · **avoid colours close to #83FFE7** (Poki's background) · strong contrast · one clear foreground object, simple background · suggest motion · must closely match the actual game · after the fit test, changes need Poki sign-off | [POKI-THUMB] |

### Animated thumbnail (Poki's "preview video")
| Spec | Value | Source |
|---|---|---|
| Required? | Added in **Soft Release**; **required before global release** (not for the first submission) | [POKI-PAGE]; [POKI-REQ] |
| Size / ratio | **1:1 square, 1080×1080 or higher** | [POKI-PAGE] |
| Frame rate | **50 fps or higher** | [POKI-PAGE] |
| Length | **4–6 s**, 2–3 scenes of about 1–2 s each | [POKI-PAGE] |
| Audio | **Muted** (the site never plays sound) | [POKI-PAGE] |
| Format / max | **.mp4, ≤100 MB** | [POKI-PAGE] |
| Content | Gameplay-focused · minimal text · **start from the static artwork** · hide non-essential UI · **centre the action (square crop trims edges)** · no cursor | [POKI-PAGE] |

### Screenshots / icons
- **Submission form ("Share your game"): 3 screenshots of actual gameplay, static PNG, JPEG or WebP, ≤5 MiB each.** No size stated [POKI-SHARE]. No separate icon spec found.
- Context (not an asset rule, but it affects capture): Poki's hard requirements include a **16:9 game frame scaled to 640×360 / 836×470 / 1031×580**, plus mobile full-screen in portrait or landscape [POKI-REQ]. Our portrait-first 390×844 board needs the landscape-backdrop layout on desktop, which ART_DIRECTION §3 already plans. Screenshots will come from that frame.

## 3. GameDistribution (third lane)
### Thumbnails: 3 required, 2 optional
| Spec | Value | Source |
|---|---|---|
| Mandatory | **512×512 (1:1), 512×384 (4:3), 200×120 (5:3)** | [GD-DEV] §5.1; [GD-DES]; [GD-FAQ]; [REQ] l.28 |
| Optional ("encouraged", used in banners) | **1280×720 (16:9), 1280×550 (~2.33:1)** | [GD-DES]; [GD-FAQ] |
| Format | ⚠️ **Not stated** in the GD pages I could read. A third-party summary (https://portalready.world/portals/thumbnails-and-metadata/) says **JPG**, citing GD's quality guidelines, but the public quality-guidelines page I fetched doesn't show it. Confirm in the upload form; exporting JPG (flattened, q≥90) is the safe default | [GD-DEV]; third-party |
| Max file size | Not published ⚠️ | — |
| Safe zones | None numeric. "Cropping the art is allowed (same art on all sizes), but keep in mind how you crop" · **cropped-off titles or characters = immediate decline** | [GD-DES] |
| **Text / logo** | **Optional but appreciated, especially on larger thumbnails**; must be readable and not dominate [GD-DEV]. Design guide: put the title **only on the 1280s** (limited space on the 512s) · **200×120: no (game) logo**, no small details · logo "not mandatory" | [GD-DEV] §5.1; [GD-DES] |
| Other rules | Reflect the game (genre and goal), gameplay art or custom design · not a screenshot / not UI-heavy · no CTA buttons or UI · sharp eye-catcher · good contrast, avoid greyscale · different designs per size "appreciated" | [GD-DES]; [GD-FAQ] |
| **Immediate declines** | IP infringement (look-alikes OK only if clearly adjusted) · stretched or squeezed · unintentionally blurry or pixelated · white borders/lines on the sides · cropped titles or characters · art duplicated from another GD game · **only logo or text** · lots of empty space · spelling mistakes · misleading or clickbait. "Declined" examples also list **rounded borders** and too many UI elements | [GD-DES] |

### Video / icons / screenshots
- **No preview-video spec is published** by GD, and I found no video field in the public docs ⚠️ (the upload form needs a login). The third-party summary also reports "Not published".
- No separate icon or screenshot requirement found. The 512×512 serves as the square/icon use ("catalog, search, splash screen"; publishers may reuse it) [GD-DEV] §5.1.

---

## 4. TT Art's plan vs the specs
TT Art plan: covers 1920×1080, 800×1200, 800×800 · 15–20 s silent previews in landscape and portrait · no logo or title for now.

| # | Item | Verdict |
|---|---|---|
| 1 | CG three cover sizes | ✅ Exact match [CG-COV] |
| 2 | **No title on covers** | ✅ **Allowed on CG**: the title isn't required, and the restriction is only that nothing *other* than the title appears. But CG *recommends* the title (memorability, distinctness). Plan a title variant once the name is picked. ✅ Ideal for Poki (avoid text). ✅ OK for GD (text optional; never on 200×120) |
| 3 | No logo | ✅ Required anyway: CG bans icons/logos, Poki avoids text, GD forbids a logo on 200×120. **Keep the PKD logo off all covers** |
| 4 | **Portrait preview ratio** | ⚠️ **Must be 2:3 (1080×1620)**, not phone 9:16 (e.g. 1080×1920 or our 390×844 game ratio ≈ 0.46). A straight capture of the portrait game will need a 2:3 frame, which means a background extension, *not* black bars (banned) [CG-COV]; [FF-PB] l.12 |
| 5 | Portrait video accepted? | ✅ CG: yes, it's one of the two required formats. ❌ Poki: **square 1:1 only**. ❓ GD: no video spec published |
| 6 | **Poki animated thumbnail missing** | ❌ Not in the plan. Needs a **1:1 ≥1080×1080, 4–6 s, ≥50 fps, muted .mp4** (needed by global release, not first submission). The CG 15–20 s cuts can't be reused as-is (length, ratio, fps) |
| 7 | Preview frame rate | ⚠️ If the CG previews are recorded at 30 fps, the Poki cut can't be made from them. **Record master gameplay at 60 fps** |
| 8 | Preview opening frame | ⚠️ CG previews must **open on the static cover**. If a titled cover is added later, the preview opening frames must be re-cut to match |
| 9 | **GD thumbnails missing** | ❌ The plan has no 512×512 / 512×384 / 200×120 (mandatory) or 1280×720 / 1280×550 (optional). 512×512 and 1280×720 are clean downscales; 512×384, 200×120 and 1280×550 need deliberate crops (see §5) |
| 10 | Poki static thumbnail | ✅ 800×800 meets ≥628×628 (check it reads at small sizes; keep detail off the rounded corners; avoid colours near #83FFE7. Our sage #55724E and pistachio #B8DFA6 are well away, but check any mint décor) |
| 11 | Screenshots | ❌ Not in the plan. Poki's submission form asks for **3 real gameplay screenshots** (PNG/JPEG/WebP ≤5 MiB). CG and GD ask for none |
| 12 | Silent | ✅ CG requires no sound (ship **no audio track**, as FF did). Poki is muted anyway |
| 13 | Format | Covers: PNG for CG (FF-proven), JPG for GD (⚠️ unconfirmed). Video: MP4 H.264 + faststart |
| 14 | Covers vs in-game art | ⚠️ Art direction is still a proposal (B pending Shahar). Covers must be cut from the gated build, or they'll be redone like FF's [FF-PB] l.11, l.20 |

## 5. One master set that covers all three portals (recommendation)
1. **Key art master, landscape:** 3840×2160 layered source (PSD/Krita or a `ttdraw` scene) with the **hero group** (cake stand, round fluted tarts on the tray, a teapot, a glimpse of the board) inside the **central ~1080×1080 of the 1920 frame** (i.e. the middle 56% of the width). That one square safe area then yields:
   - CG 1920×1080 → GD 1280×720 (downscale)
   - CG 800×800 → Poki ≥628 (use 1080×1080 or 800×800) → GD 512×512 (centre square crop)
   - GD 512×384 (4:3) and GD 200×120 (5:3): crops around the hero. For **200×120, simplify**: hero tart and board only, no small décor
   - GD 1280×550 (2.33:1): a full-width 1920×823 crop of the 1920×1080 frame, so keep the hero inside the middle ~76% of the height
   - Poki has no title. Keep corners clear for its rounded mask
2. **Key art master, portrait:** a separate 1600×2400 composition (re-stacked layers, not a crop; a 2:3 crop of a 1080-tall landscape would be upscaled and soft) → CG 800×1200.
3. **Two text states per image:** `notext` (now; used for Poki, GD 512s and 200×120, CG until the title exists) and `title` (later, CG covers and GD 1280s only). Nothing other than the title, ever.
4. **Gameplay capture master:** record **60 fps**, no cursor, no audio, from the gated build, in two frames: desktop 1920×1080 (landscape backdrop layout) and a 1080×1620 2:3 portrait frame (portrait board with backdrop filling the top and bottom, no bars). Cut from it:
   - **CG landscape** 1920×1080, 15–20 s (aim 16–18 s), opening on the landscape cover
   - **CG portrait** 1080×1620, same rules, opening on the portrait cover
   - **Poki animated** 1080×1080, 4–6 s, ≥50 fps, 2–3 scenes, opening on the square art, centred action
   - All **H.264 MP4, `-an`, `+faststart`**, well under 50 MB
5. **Screenshots:** 3× PNG gameplay frames from the same capture (Poki form; also useful for a GD or CG description).
6. **Naming:** `<portal>-<use>-<WxH>-<notext|title>_<buildsha>.<ext>`, so every asset is traceable to the build [FF-PB] l.20.

## 6. Guardrails for every asset (from CG_READINESS.md §top-items 3–4, TM, ART_DIRECTION)
- **No Pop-Tarts trade dress** [CGR item 3; TM]: no rectangular frosted toaster pastries, **no sprinkles**, no "pop" wordplay or styling, no lookalike logo. Kellogg has pending POP-TARTS filings covering browser games (IC 41) and puzzles (IC 28). Every tart is **round and fluted** (berry, lattice, lemon), and art must read as *tea-room pastries*. Portal searches already surface a "Mini Pop Tarts" cooking game, so don't look like it. (GD also declines IP look-alikes unless "clearly adjusted" [GD-DES].)
- **Adult cozy, not kids** [CGR item 4]: CG rejects games "targeted for kids". The audience is women 35+. Use the restrained palette (plum ink, sage, pewter, serif headings), no mascots, faces or toy-like chunky shapes, and keep any wording plainly about pastry (PEGI 12).
- Consistency with Sudoku Dash: indoors, inland tea room; no sea, teal/navy or coffee (ART_DIRECTION).
- Provenance: AI-tools disclosure on CG covers anything AI-touched. Current art is procedural in-house with OFL fonts (ART_DIRECTION, CGR item 8).

## 7. Unverified / not checked
- **CG:** accepted image formats beyond PNG, image file-size limit, video codecs beyond H.264 MP4, frame rate, and whether "1080p 2:3" could also mean 720×1080 (FF's 1080×1620 was accepted). The developer portal form needs a login and wasn't opened.
- **Poki:** static thumbnail format and file-size limit; any icon/screenshot specs inside Poki for Developers (login).
- **GD:** image format (JPG claim is third-party only), file-size limits, whether the upload form has any video/GIF field, and any icon field (login).
- I found no published numeric safe zones for any portal. §5's safe areas are my recommendation.
- REQUIREMENTS.md (2026-09-18) predates these docs. Its GD thumbnail line matches; it has no cover or video specs.
