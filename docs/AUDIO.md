# Audio (tea-bakery)

## Music loop (SPEC §8: one calm loop)
- File: `assets/audio/music_loop.ogg` (Vorbis q3, mono 32 kHz, 41.14 s = 12 bars at 70 BPM, ~132 KB). Import: `loop=true`, offset 0.
- Provenance: 100% original, synthesised by `tools/make_music_loop.py` (sine/FM keys, pad, plucked arpeggio, simple delay
  room; fixed seed). No samples, recordings, presets or third-party material, so no licence to track. Re-running the
  script reproduces the file byte-for-byte (ffmpeg libvorbis, bitexact flags).
- Seamless: the 12-bar pattern is rendered three times and the steady-state middle copy is cut, so the tail of the last
  bar is already in the first bar. `tools/check_music_loop.py` (CI step 1d) decodes the OGG and checks the seam (jump,
  click energy, level step vs the other bar lines), 30-60 s, < 600 KB, peak <= -3 dBFS and RMS.
- Playback: `Sfx` autoload, `Music` bus (-12 dB, sends to Master). Starts only after the first tap/click/key
  (`Sfx.gestured`); Settings Music off stops it and mutes the Music bus. Every Master mute reason (portal muteAudio,
  tab hidden, blur, ad, Sound off) silences it; on the web PKD_AUDIO also suspends the WebAudio context.
