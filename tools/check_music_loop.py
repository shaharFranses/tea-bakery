#!/usr/bin/env python3
"""Loop-point + budget check for the §8 music loop. usage: tools/check_music_loop.py [ogg] [json_out]
Decodes the shipped OGG with ffmpeg and checks: 30-60 s, mono, file < 600 KB, peak <= -3 dBFS, quiet RMS,
and the loop seam (last sample -> first sample) is continuous: the jump across the seam is no bigger than the
sample-to-sample steps right around it, and the high-frequency (click) energy in a 5 ms window across the seam
is no higher than in the neighbouring windows, and the level step across the seam (a bar line) is like the
other bar lines'. Exit 1 on any FAIL."""
import json, os, subprocess, sys
import numpy as np
ogg = sys.argv[1] if len(sys.argv) > 1 else "assets/audio/music_loop.ogg"
raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", ogg, "-f", "f32le", "-ac", "1", "-"], capture_output=True, check=True).stdout
x = np.frombuffer(raw, dtype="<f4").astype(np.float64)
pr = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=sample_rate,channels,codec_name", "-of", "json", ogg],
                    capture_output=True, text=True, check=True)
st = json.loads(pr.stdout)["streams"][0]; sr = int(st["sample_rate"])
res, info = {}, {}
dur = len(x) / sr; size = os.path.getsize(ogg)
peak = 20 * np.log10(np.max(np.abs(x))); rms = 20 * np.log10(np.sqrt(np.mean(x ** 2)))
info.update(duration_s=round(dur, 3), samples=len(x), sample_rate=sr, codec=st["codec_name"], channels=st["channels"],
            bytes=size, peak_dbfs=round(peak, 2), rms_dbfs=round(rms, 2))
res["duration_30_60s"] = bool(30 <= dur <= 60)
res["mono_vorbis"] = bool(st["channels"] == 1 and st["codec_name"] == "vorbis")
res["size_lt_600KB"] = bool(size < 600 * 1000)
res["peak_le_-3dBFS"] = bool(peak <= -3.0)
res["quiet_rms_-40_to_-16dBFS"] = bool(-40 <= rms <= -16)
# seam: treat the file as a ring (as the player does with loop=true)
W = 2000
ring = np.concatenate([x[-W:], x[:W]])                 # seam sits between index W-1 and W
d = np.abs(np.diff(ring)); jump = d[W - 1]; near = np.max(np.delete(d, W - 1))
info.update(seam_jump=float(jump), seam_neighbour_max_step=float(near), first=float(x[0]), last=float(x[-1]))
res["seam_jump_le_neighbour_steps"] = bool(jump <= 1.5 * near + 1e-4)
hp = np.abs(np.diff(ring, 2))                          # 2nd difference ~ click energy
win = int(0.005 * sr)
def e(c): return float(np.sqrt(np.mean(hp[c - win // 2:c + win // 2] ** 2)))
seam_e = e(W - 1); neigh = [e(W - 1 + k * win) for k in (-3, -2, 2, 3) if win // 2 <= W - 1 + k * win < len(hp) - win // 2]
info.update(seam_hf_rms=seam_e, neighbour_hf_rms=neigh)
res["seam_no_click_hf_energy"] = bool(seam_e <= 2.0 * max(neigh) + 1e-5)
# level continuity: the seam is a bar line (12 bars, loop starts on the downbeat of bar 1), so the 50 ms RMS step across
# it must be no larger than across the other 11 bar lines inside the loop (+1 dB): it sounds like any other downbeat.
BARS = 12; n50 = int(0.05 * sr); bar = len(x) / BARS
def step(i): a = np.sqrt(np.mean(ring_full[i - n50:i] ** 2)); b = np.sqrt(np.mean(ring_full[i:i + n50] ** 2)); return 20 * np.log10(b / a)
ring_full = np.concatenate([x[-n50:], x, x[:n50]])
seam_step = step(n50); inner = [step(n50 + int(round(k * bar))) for k in range(1, BARS)]
info.update(seam_rms_step_db=round(seam_step, 2), barline_rms_steps_db=[round(v, 2) for v in inner])
res["seam_level_step_like_other_barlines"] = bool(abs(seam_step) <= max(abs(v) for v in inner) + 1.0)
for k, v in res.items(): print(("PASS " if v else "FAIL ") + k)
print("info", json.dumps(info))
if len(sys.argv) > 2: json.dump({"checks": res, "info": info}, open(sys.argv[2], "w"), indent=1)
sys.exit(0 if all(res.values()) else 1)
