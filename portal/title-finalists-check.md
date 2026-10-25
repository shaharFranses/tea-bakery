# tea-bakery: title finalists, trademark and name sanity check
Prepared 2026-10-25, ~08:40–09:05 (Asia/Jerusalem), by TT Portal Ops. Research only: no sign-ins, purchases, domain registrations or messages.
Finalists (all `<Title>: Bakery Logic Puzzle`), per Growth `/workspace/audience/game4-titles-v2.md`: 1) Teacake Lane, 2) Scone Street, 3) Little Tea Room.

> **NOT LEGAL CLEARANCE.** This is a desk sanity check by a non-lawyer using public registers and web results. It is not a clearance search or legal opinion. Get attorney clearance before any trademark filing, merch or store-app launch.

## Summary
| Rank | Title | Risk | One-line reason |
|---|---|---|---|
| **1** | **Teacake Lane** | **LOW** | No TEACAKE LANE mark anywhere (USPTO or TMview). Every TEACAKE mark is in food/retail classes and most are dead. The only live game-class neighbour is TEACAKES & TELLS (IC 41, film/podcast production). No game uses the name. Both domains are free. |
| 2 | Scone Street | **LOW–MEDIUM** | The exact name is clean, but it sits next to **SWEET STREET**: a live US registration in **IC 9/41 for electronic games** (Playstudios), plus two 2026 "Sweet Street" bakery/cozy games. Weak search identity ("scone street" fuzzes to "sweet street"). |
| 3 | Little Tea Room | **MEDIUM** | Not a trademark collision in the US, but **generic**. There's a crowded field of "Little … Tea House/Shop" games (Little Corner Tea House: 1M+ Play downloads). "The Little Tea Room" is a quest location in Rebellion's *Atomfall* (2025) that dominates search. There's a JP registration for "Little Tea Room" (class 43). Weak distinctiveness, and it conflicts with CG's non-generic title guideline. |

**Recommended order: Teacake Lane → Scone Street → Little Tea Room** (same as Growth's). The gap between #1 and #2 is bigger than Growth's notes suggest, because of SWEET STREET.

## Method
- **USPTO:** queried the public backend of USPTO Trademark Search (https://tmsearch.uspto.gov/, endpoint `prod-stage-v1-0-0/tmsearch`), live and dead. Queries: exact phrases, wildcards (`TEACAKE*`, `SCONE*`, `TEAROOM*`, `TEAHOUSE*`, `TEACUP*`), fuzzy edit-distance-1 sound/spelling variants (`TEACAKE~1`, `SCONE~1`), and hand-picked sound-alikes and pattern-alikes ("TEA CAKE", "TEA CAKE LANE", "TEA LANE", "CAKE LANE", "CUPCAKE LANE", "PANCAKE LANE", "TEACUP LANE", "SCONE ST", "STONE STREET", "SWEET STREET", "BAKER(Y) STREET", "SCONE ZONE", "TEA ROOM", "TEA HOUSE", "TEA SHOP", "LITTLE TEA …"). Results were filtered to classes 9/28/41, and the relevant records opened (full goods, status, owner, dates). Any record can be checked on TSDR: `https://tsdr.uspto.gov/#caseNumber=<serial>&caseType=SERIAL_NO&searchType=statusSearch`
- **EU/UK/international:** **TMview answered a plain request** (POST to `https://www.tmdn.org/tmview/api/search/results`; I sanity-checked it with "pop-tarts", which returned 136 Kellogg records across many offices). TMview aggregates EUIPO and many national offices, including UK (GB) records, which showed up in the results. For large result sets I reviewed only the first 100 per query (see Not checked).
- **Stores:** Steam store-search API; iTunes Search API (US); Google Play store search page (US); itch.io search; CrazyGames search API (`api.crazygames.com/v3/en_US/search`, undocumented); Poki search API (`api.poki.com/search/query/3`); GameDistribution public GraphQL `gamesSearched` (sanity: "cake" = 118 hits, "bakery" = 19).
- **Domains:** Verisign RDAP (`https://rdap.verisign.com/com/v1/domain/<name>`). 404 means unregistered at check time.

---

## 1) Teacake Lane: LOW
**USPTO (classes 9/28/41 + all classes):**
- `TEACAKE LANE`, `TEA CAKE LANE`, `TEACAKE STREET`, `TEA LANE` (games), `CAKE LANE`, `TEACUP LANE`, `PANCAKE LANE`: **0 records.** The only `TEA LANE` hit is TEA-LANE (85703743), tea beverages, IC 30, dead.
- `TEACAKE*`: 17 records, **16 dead**, mostly IC 30/35 bakery, e.g. TEACAKE BAKE SHOP (77341089/92/95/99, cancelled) and TEACAKE (85187164, The Wine Group, wine, abandoned).
- **Only live TEACAKE mark: TEACAKES & TELLS**, Reg 8483287 (serial 99683429, filed 2026-03-04), **IC 41: film and video production; multimedia entertainment content production; photography; podcasts.** It's a different phrase and different services (media production, not games). Low conflict risk, but it is the nearest live game-class neighbour. https://tsdr.uspto.gov/#caseNumber=99683429&caseType=SERIAL_NO&searchType=statusSearch
- `TEA CAKE`: TEA CAKE KIDS (74204003, IC 28 dolls / card games / play tea sets) is **cancelled**. TEA CAKE KING (Reg 6764250, live) is IC 30 food only.
- Fuzzy `TEACAKE~1`: nothing new in game classes.
- `TEACUP*` in game classes: STORM IN A TEACUP (Reg 6959378, IC 9/42, an Italian game developer) and TEACUP SOFTWARE (Reg 3351710, IC 9). Different words. Noted only because "teacup" was Growth's dropped alternative (teacuplane.com is also registered, RDAP 200).

**TMview:** `teacake lane` 0. `tea cake lane` 1 irrelevant (PT "PLANET OF CAKES – PASTRY & TEA HOUSE", cl. 43, expired). `teacake` 32: food/retail marks (GB "Bumblebakes and Teacakes" cl. 30; GB "Teacake's and Allsort's" cl. 43; CN O.TEACAKE / MYTEACAKE in non-game classes; FR "TeaCakes Bake Shop" expired). The only game-class items are the two US records above. **No EU (EM) or GB TEACAKE mark in classes 9/28/41.**

**Games and apps:** CrazyGames 0 ("teacake lane", "teacake", "tea cake"); Poki 0 (fuzzy "teacher" results only); GD 0; Steam 0 ("teacake", "teacake lane"); App Store: no app named Teacake/Teacake Lane; Google Play: none (nearest: Little Corner Tea House, Cake Sort). itch.io: no "Teacake Lane". Near names: *Temple of Teacakes* (https://temmy.itch.io/temple-and-teacakes), *Teacade* (https://lianes8.itch.io/teacade), and a dev account "teacakegames" (https://teacakegames.itch.io/lugal). All are small and none is a bakery logic game.

**Domains:** teacakelane.com **404 (free)**, teacakelanegame.com **404**, playteacakelane.com **404**.

**Lookalike / SEO:**
- Web: "Teacake Lane" is a historical nickname for Quarry Road, Woodlesford (UK) (https://newwoodlesford.xyz/gallery/). No business or product found.
- "Teacake" on its own is a generic food word. In the UK it strongly evokes **Tunnock's Teacakes**, but Tunnock's US marks are for TUNNOCK'S (Reg 6182433, 5830973; IC 30), not TEACAKE, and none was found in TMview's first 100 "teacake" results. Keep the art away from Tunnock's red/silver foil-wrapped dome look.
- SEO: "teacake" searches are dominated by recipes. The full phrase "Teacake Lane" is essentially uncontested, which is good for owning the name.

**Risk: LOW.** Watch item: TEACAKES & TELLS (IC 41 media production).

## 2) Scone Street: LOW–MEDIUM
**USPTO:**
- `SCONE STREET`, `SCONE ST`: **0 records.** `STONE STREET` (a sound-alike): 13 records, **none in 9/28/41**. Live ones are coffee (FP Enterprises / Coperaco, IC 30/40/43) and finance.
- `SCONE*` in game classes: SCONEKAT (Reg 6887132, IC 41 music, live), SCONEY SINATRA (IC 9 music, dead), SCONE ZONE (78029024, IC 41 scone workshops, abandoned), THE STROLLING SCONES (IC 41 band, cancelled). None are games.
- **Pattern-alike, the key finding: `SWEET STREET`**
  - **Reg 6570570 (serial 90135421), Playstudios, Inc. Live. IC 9: "Downloadable software in the nature of a mobile application for playing electronic games"; IC 41: "providing online electronic games."** In practice it's a slot game inside myVEGAS Slots (https://play.google.com/store/apps/details?id=com.playstudios.myvegas; Playstudios portfolio: https://markinton.com/company/playstudios-inc).
  - **SWEET STREET EST. 1979** (Reg via 86677549, Sweet Street Desserts, Inc., live, IC 30/41/42), a large US dessert manufacturer.
  - Mattel's SWEET STREETS toy marks (IC 28) are all dead.
- `BAKER STREET` game marks exist (BAKER STREET MYSTERY, Huuuge, IC 9/41, live; 221 B BAKER STREET board game, IC 28, live). This is a different word and only shows "___ Street" titles are common in games.

**TMview:** `scone street` 0. `scone` 1,101 (first 100 reviewed): game-class hits are unrelated software or places (EM SCONE, Scontain GmbH, cl. 9 software, EUTM 019392936; AU "HORSE CAPITAL OF AUSTRALIA SCONE", a town). `sweet street` 215 (first 100): beyond the US marks, **AU SWEET STREET (Anna Polyviou, pastry chef) in cl. 16/30/41 and cl. 35/38/41, registered.**

**Games and apps:** "Scone Street": CrazyGames 0, Poki 0 (fuzzes to "Sweet Run / Sweet World / Street…"), GD 0, Steam 0, App Store 0, Google Play 0, itch.io 0 (only "street scene" assets). **But "Sweet Street" is live in games:**
- *Sweet Street: Merge Cake Shop* (Skilljoy, iOS, March 2026; a dessert-shop merge game): https://apps.apple.com/us/app/sweet-street-merge-cake-shop/id6759883255, https://www.taptap.io/app/33977393
- *Sweet Street* (Steam app 5197950, coming soon; tagged Cozy, Relaxing, Time Management): https://isthereanydeal.com/product/01a0927c-6bab-71ef-916b-f59e74e97f46/
- a small web game "sweet street bakery" (https://mable.gg/g/g7pwhe)
- Scone-themed itch games: *Tea 'N' Scones*, *Supreme Scone Store*, *Scones of Destiny*. Steam: *Jolly Good: Tea and Scones*.

**Domains:** sconestreet.com **404 (free)**, sconestreetgame.com **404**.

**Lookalike / SEO:**
- "Scone" is also a place: Scone, Perthshire (Scotland) and Scone, NSW (Australia). Real "Scone Street"s exist, e.g. in Evandale, Tasmania (https://en.wikipedia.org/wiki/en:Evandale,_Tasmania).
- US pronunciation is split ("skone"/"skon"). Search engines and portal search fuzz "scone street" to "sweet street", which puts us next to three Sweet Street games.

**Risk: LOW–MEDIUM.** A legal likelihood-of-confusion claim from SWEET STREET looks weak to me as a non-lawyer: the dominant words differ (scone vs sweet), and Playstudios' use is a slot game. But the structure is the same ("S… Street"), the bakery meaning overlaps, and the mark is live in our exact game classes. Discoverability is also worse.

## 3) Little Tea Room: MEDIUM
**USPTO:**
- `LITTLE TEA ROOM`, `LITTLE TEAROOM`, `LITTLE TEA SHOP`: **0.** `LITTLE TEA HOUSE`: 1 (THE BEST LITTLE TEA HOUSE IN TEXAS, serial 99200002, IC 21/25, pending). LITTLE TEA COMPANY (99714249, IC 5/30, allowed).
- `TEA ROOM` in game classes (6 of 106 records): live ones are BROADWAY AT THE RUSSIAN TEA ROOM (Reg 7013908, IC 41 radio program). Dead: THE TEA ROOM (99337363, IC 41 media), RAINBOW TEA ROOM, MEGAN'S ENCHANTED FOREST TEA ROOM.
- **The Russian Tea Room** (NYC landmark) holds live marks RUSSIAN TEA ROOM / THE RUSSIAN TEA ROOM (Regs 1229752, 1305839/40, 1261105, 1306293, 1005631) for restaurant services, cookbooks, bags and matches. Not games, but it's the famous "Tea Room" brand.
- `TEAROOM*`: OXFORD TEAROOM MYSTERIES (Reg 5666546, IC 9/16, novels/audiobooks, live). `TEAHOUSE*`: TEAHOUSE STUDIOS (IC 41 audio, live).

**TMview:** `little tea room` 2: **JP "Little Tea Room" (2016122777, registered, cl. 43)**; FR "Little Miss Cookies Tea room Salon de thé" (cl. 41/43, ended). `tearoom` 138 (first 100): GB OXFORD TEAROOM MYSTERIES (UK00003712247, cl. 9/16); GB THE WILLOW TEAROOM (UK0002251332A, cl. 9 among others); DE "tearoom" cl. 9/14/25/28 (expired). `tea room` 852 (first 100): ES "TEA ROOMS" (M4210280, cl. 38/41, BOOMERANG T.V.); US ROOM FOR TEA (Reg via 88655317, IC 41).

**Games and apps:**
- **Little Corner Tea House** (Loongcheer, a tea-house sim; **1M+ downloads** on Google Play, 445 reviews; App Store 68 ratings): https://play.google.com/store/apps/details?id=com.loongcheer.unicon.littlecornerteahouse, https://apps.apple.com/us/app/little-corner-tea-house/id6670783458
- itch.io: *Little Tea Shop* (https://foodwithouttaste.itch.io/little-tea-shop), *Little Bunny Tea Shop*, *A Little Tea House (Web Demo)*, *Dormouse Tea Room*, *Haiku Tea Room*, *The Tea Room*, *Little Katy's Tea Party*
- **Atomfall** (Rebellion, 2025): "The Little Tea Room" is a named location and quest lead, with many guides ranking for the phrase (https://www.neoseeker.com/atomfall/walkthrough/Little_Tea_Room, https://www.dualshockers.com/atomfall-investigate-the-little-tea-room-lead-guide/)
- CrazyGames/Poki/GD/Steam/App Store: no exact title.

**Domains:** littletearoom.com **404 (free)**, littletearoomgame.com **404**.

**Lookalike / SEO:** "Little Tea Room" is a common real-world café name. For game searches, Atomfall guides dominate. It's descriptive (hard to protect or own), and CG's quality guideline asks for unique, non-generic names (https://docs.crazygames.com/requirements/quality/).

**Risk: MEDIUM.** The low legal-conflict risk is outweighed by genericness, crowding, and the JP "Little Tea Room" registration (restaurant class).

---

## Note on the earlier title (Tea & Tarts)
TMview answering means one gap in `trademark-check.md` can now be partly closed: TMview "tea & tarts" returned 0 results and "tea and tarts" 2 unrelated ones (GB "TaRTS Trauma and Resuscitation Team Skills", cl. 41; a US vodka slogan). The title is being retired anyway.

## Checked / Not checked
**Checked (2026-10-25):**
- USPTO register (tmsearch backend), live and dead: exact, wildcard, fuzzy and hand-picked sound/pattern-alikes for all three names, filtered to IC 9/28/41. Key records opened: 99683429 TEACAKES & TELLS, 90135421 SWEET STREET, 86677549 SWEET STREET EST. 1979, 97062245 and the Russian Tea Room regs, the 88000250 OXFORD TEAROOM MYSTERIES list entry, 79321570 STORM IN A TEACUP, the STONE STREET live set, the LITTLE TEA live set, and TUNNOCK'S.
- TMview (EUIPO plus national offices including GB), with exact and contains queries for all three names and the main variants.
- Stores: CrazyGames, Poki, GameDistribution (APIs); Steam; App Store US; Google Play US (search page); itch.io.
- Domains (Verisign RDAP): teacakelane.com, teacakelanegame.com, playteacakelane.com, sconestreet.com, sconestreetgame.com, littletearoom.com, littletearoomgame.com: all 404 (free). teacuplane.com: 200 (taken).
- Web search for businesses, streets and famous uses of each name.

**Not checked / limits:**
- **UKIPO direct search** (trademarks.ipo.gov.uk): **unreachable**, HTTP 403 with a captcha. GB records were seen only via TMview.
- **WIPO Global Brand Database**: **unreachable** by plain request (JS shell; `api.branddb.wipo.int` returned 403). Whether TMview covers Madrid/WIPO international registrations wasn't separately verified.
- **EUIPO eSearch** directly: not used (JS app). EU marks were seen only via TMview.
- TMview large result sets were reviewed only to the **first 100** results: `tea cake` (344), `scone` (1,101), `sweet street` (215), `tea room` (852), `tearoom` (138).
- TSDR document files (office actions, specimens) were not opened. USPTO design-code / logo searches were not run. Phonetic matching beyond edit-distance-1 and the hand-picked list was not done.
- State registers, company registries and common-law use beyond web search. Other TLDs (.co.uk, .io, .games).
- Google Play beyond the first results page; Poki, CG and GD match titles only (fuzzy), not mechanics.

**Not legal clearance.** Nothing here is legal advice. A trademark attorney should clear the chosen title before filings, merch or store apps.
