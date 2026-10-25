Landscape desktop backdrop hook (ART drops the asset here).
File: res://assets/backdrop/backdrop_landscape.png (or .webp). Suggested 1920x1080, inland tea-room scene,
calm/low-contrast centre (the 390-480 px portrait play column sits on top of it, centred).
scenes/main.gd loads it if present and shows it only when the viewport is landscape (width > height);
otherwise a flat placeholder colour is used. Portrait phones never show it.
