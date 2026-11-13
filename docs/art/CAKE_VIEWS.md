# Cake art: side + top views (request for Art)

**Why:** the 8 chapter cakes are drawn from mixed angles. Three are **side views** (scone, Victoria slice, macaron),
five are **top views** (lemon, apricot, Bakewell, berry, custard tarts). The new home-screen display shelves are seen
from the side, so a top-view tart on a stand looks wrong (it floats like a flat disc). The board and the Recipe Book
want the opposite (top view reads best on the grid). Each cake therefore needs **both** versions.

## What exists today (keep unchanged, still used on the board)

| Chapter | File (`assets/board/`) | Cake | Current view |
|---|---|---|---|
| 1 | `cake_scone` | Scone + clotted cream + cherry | **side** |
| 2 | `cake_victoria` | Victoria sponge slice | **side** |
| 3 | `cake_lemon` | Lemon drizzle tart | **top** |
| 4 | `cake_apricot` | Jam tart (apricot) | **top** |
| 5 | `cake_bakewell` | Cherry Bakewell | **top** |
| 6 | `cake_berry` | Strawberry shortcake / berry tart | **top** |
| 7 | `cake_custard` | Apple crumble / custard tart | **top** |
| 8 | `cake_macaron` | Macaron | **side** |

## What to draw

For every cake, the view it does **not** have yet:

| New file | Needed view | Notes |
|---|---|---|
| `cake_scone_top` | top | scone from above: round bun, cream dollop + cherry in the middle |
| `cake_victoria_top` | top | round sponge from above: jam spiral / dusted sugar, one slice cut out |
| `cake_lemon_side` | side | tart in profile: fluted crust edge, glossy lemon dome, drizzle |
| `cake_apricot_side` | side | jam tart in profile: fluted crust, domed apricots |
| `cake_bakewell_side` | side | Bakewell in profile: icing top with the feather line, cherry on top |
| `cake_berry_side` | side | berry tart in profile: crust, piled berries |
| `cake_custard_side` | side | crumble/custard tart in profile: crust, crumbly golden top |
| `cake_macaron_top` | top | macaron from above: round pink shell with a small highlight |

Result: 16 sprites in total, each cake as `cake_<name>` (existing view), plus the 8 new ones above. To keep the
names self-explanatory, please also add `cake_<name>_side` / `cake_<name>_top` copies for the existing ones
(identical pixels), so code can always ask for `_side` or `_top` without knowing the legacy view.

## Spec (same as the existing cakes)

- 256x256 px (`@2x`) and 128x128 px (1x), transparent PNG, subject centred, bottom of the cake at ~92% of the height
  for **side** views (so it can sit on a plate), centred for **top** views.
- Same style: plum ink outline (`#43283A`), thick cream sticker outline, flat fills with one small highlight, the
  same palette as the current sprites (`docs/art/STYLE_GUIDE.md`, `ui/theme/art_palette.gd`).
- Same silhouette size per cake as today (a side view should look like the same cake as its top view: same
  colours, toppings and proportions).
- Side views should be about as wide as tall (or a bit wider) so three fit across a plate.
- Names/paths: `assets/board/cake_<name>_side.png`, `..._side@2x.png`, `..._top.png`, `..._top@2x.png`.

## Where each view is used

- **Side:** home-screen display shelves (stands, plates, dome, jar), chapter-end drop.
- **Top:** board cells and the Recipe Book card art.

## Display pieces for the home shelves (engineering draws these in code for now; Art may replace later)

tiered stand, footed plate, flat plate, glass cake dome, cupcake/jar display. Optional Art pieces if wanted:
`display_dome`, `display_plate`, `display_footed`, `display_tiered`, `display_jar` (side view, 256 px, transparent).
