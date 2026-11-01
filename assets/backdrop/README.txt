Backdrops (TT Art drop P2; SPEC v1.0.1 wide re-layout). Lossy WebP, imported Lossy with mipmaps off.

backdrop_landscape.webp (1920x1080): desktop / wide layout (any page wider than tall, incl. the 800x450 CrazyGames
  embed). Cover-fit. The board sits on the LEFT (over the calm dresser side) and the side panel on the right, next to
  the window and countryside. There is no centred portrait column any more.
backdrop_portrait.webp (1080x2340): phones (portrait) on Home, the Recipe Book and the chapter end only.
  Cover-fit, anchored top. The phone board screen keeps the flat ROSEWATER_BG wallpaper behind the tray.

scenes/main.gd picks the texture in _apply_backdrop() from the layout (landscape/portrait) and `screen`.
This README is excluded from the export.
