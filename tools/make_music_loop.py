#!/usr/bin/env python3
"""Synthesise the §8 music loop: one calm, original tea-room loop (no samples, no third-party material).
usage: tools/make_music_loop.py [out.ogg]   (default assets/audio/music_loop.ogg; WAV scratch under PKD_WORK_DIR)
Everything is generated here from sine/FM voices with a fixed seed, so the file is reproducible and licence-clean.
Seamless loop: the 12-bar pattern is rendered three times back to back (tails and the delay/reverb run on), and the
middle copy is cut out, so whatever rings past the end of the loop is exactly what is already sounding at its start.
Needs numpy + ffmpeg (libvorbis)."""
import os, subprocess, sys, wave
import numpy as np

SR = 32000                       # mono, 32 kHz: plenty for soft keys, smaller Vorbis file
BPM = 70.0; BEAT = 60.0 / BPM; BARS = 12; BEATS_PER_BAR = 4
L = int(round(BARS * BEATS_PER_BAR * BEAT * SR))      # loop length in samples (41.14 s)
rng = np.random.default_rng(20261110)

def hz(midi): return 440.0 * 2 ** ((midi - 69) / 12.0)
# Fmaj7  Em7  Am7  Dm7 | Gsus4 G  C  Cmaj7/E | Fmaj7  Em7  Am7  Dm9  G6  Cmaj7 (back to Fmaj7 at the loop)
CHORDS = [[53, 57, 60, 64], [52, 55, 59, 62], [45, 52, 55, 60], [50, 53, 57, 60],
          [43, 50, 55, 60], [48, 52, 55, 60], [53, 57, 60, 64], [52, 55, 59, 62],
          [45, 52, 55, 60], [50, 53, 57, 64], [43, 50, 52, 59], [48, 52, 55, 59]]

def env(n, a, d):                # soft attack, exponential decay
    t = np.arange(n) / SR
    e = np.exp(-t / d)
    na = max(1, int(a * SR)); e[:na] *= np.linspace(0, 1, na) ** 2
    return e

def keys(f, dur, vel):           # gentle electric-piano: sine + soft FM bell partial
    n = int(dur * SR); t = np.arange(n) / SR
    mod = 0.9 * np.exp(-t / 0.35) * np.sin(2 * np.pi * f * 2 * t)
    x = np.sin(2 * np.pi * f * t + mod) + 0.18 * np.sin(2 * np.pi * f * 3 * t) * np.exp(-t / 0.5)
    return vel * x * env(n, 0.008, 1.4)

def pad(f, dur, vel):            # warm detuned pad, slow swell in and out
    n = int(dur * SR); t = np.arange(n) / SR
    x = sum(np.sin(2 * np.pi * f * (1 + dt) * t) for dt in (-0.0025, 0.0, 0.0025)) / 3
    sw = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.5
    return vel * x * sw

def pluck(f, dur, vel):          # harp-like arpeggio note
    n = int(dur * SR); t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t / 0.25)
    return vel * x * env(n, 0.004, 0.7)

def render_pattern(buf, off):
    bar = BEATS_PER_BAR * BEAT
    for i, ch in enumerate(CHORDS):
        t0 = off + int(round(i * bar * SR))
        def add(x, at):
            buf[at:at + len(x)] += x[:max(0, len(buf) - at)]
        add(pad(hz(ch[0] - 12), bar * 1.25, 0.10), t0)                    # bass pad, overlaps into the next bar
        for m in ch[1:]: add(pad(hz(m), bar * 1.2, 0.035), t0)
        for k, m in enumerate(ch):                                        # rolled chord on beat 1
            add(keys(hz(m + 12), 4.0, 0.06), t0 + int(k * 0.045 * SR))
        arp = [ch[1] + 12, ch[2] + 12, ch[3] + 12, ch[2] + 24]            # quiet arpeggio on the off-beats
        for b in range(BEATS_PER_BAR):
            if rng.random() < 0.8:
                add(pluck(hz(arp[b % 4]), 2.0, 0.035), t0 + int(round((b + 0.5) * BEAT * SR)))
        if i % 2 == 0:                                                     # a sparse melody note on beat 3
            m = rng.choice(ch[1:]) + 24
            add(keys(hz(m), 5.0, 0.05), t0 + int(round(2 * BEAT * SR)))

def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/audio/music_loop.ogg"
    work = os.environ.get("PKD_WORK_DIR", "/workspace/tea-and-tarts-work"); os.makedirs(work, exist_ok=True)
    buf = np.zeros(3 * L + 10 * SR)
    state = rng.bit_generator.state
    for k in range(3):           # same pattern three times (same random choices each time)
        rng.bit_generator.state = state; render_pattern(buf, k * L)
    # soft room: a few feedback delays (multi-tap) + a gentle low-pass, applied to the whole run
    wet = np.zeros_like(buf)
    for d, g in ((0.113, 0.28), (0.171, 0.22), (0.239, 0.17), (0.311, 0.12)):
        n = int(d * SR)
        wet += np.concatenate([np.zeros(n), buf[:-n]]) * g
    x = buf + 0.6 * wet
    a = np.exp(-2 * np.pi * 4500 / SR); y = np.empty_like(x); s = 0.0     # one-pole low-pass ~4.5 kHz
    for i in range(0, len(x)):
        s = (1 - a) * x[i] + a * s; y[i] = s
    loop = y[L:2 * L]            # steady-state middle copy: seamless by construction
    loop = loop / np.max(np.abs(loop)) * 10 ** (-6 / 20)                  # peak -6 dBFS (Music bus adds -12 dB)
    wav = os.path.join(work, "music_loop.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(loop, -1, 1) * 32767).round().astype("<i2").tobytes())
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "3", "-ac", "1",
                    "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", out], check=True)
    print(f"music loop: {L} samples @ {SR} Hz = {L / SR:.2f} s; wav {wav}; ogg {out} {os.path.getsize(out)} B")

if __name__ == "__main__": main()
