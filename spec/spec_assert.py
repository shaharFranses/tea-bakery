#!/usr/bin/env python3
"""Assert script for the tea-bakery spec (Playbook stage 1: economy/content assert; TT-AC-42).
Parses the ```json tunables and ```json streak_vectors blocks in SPEC.md and checks: content sums, chapter and
tutorial times, phone + wide cell math (incl. 9x9 at 800x450 per Art's wide mock), old-title/banned-name copy scan,
ad/hint/save/perf tunables, retired X-mark copy (v1.0 mold), AC bookkeeping, and the streak definition U1 against vectors V1-V11.
Usage: python3 spec_assert.py [path/to/SPEC.md]   (exit 1 on any failure)"""
import json, re, sys, pathlib, datetime as dt
p = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).with_name("SPEC.md"))
text = p.read_text()
def block(tag):
    m = re.search(r"```json " + tag + r"\n(.*?)\n```", text, re.S); assert m, tag + " block not found"
    return json.loads(m.group(1))
T = block("tunables"); V = block("streak_vectors"); fails = []; rows = []
def check(cond, msg):
    if not cond: fails.append(msg)
v = T["viewport"]; w = T["wide_layout"]; MIN = v["min_tap_px"]
# --- phone (portrait) layout
for n in range(5, 10):
    pc = (v["portrait_w"] - 2 * v["side_margin"]) / n
    if n <= T["mobile_max_size"]: check(pc >= MIN, f"phone {n}x{n} {pc:.2f}px < {MIN}")
    else: check(pc < MIN and n in T["wide_only_sizes"], f"phone {n}x{n} should be wide-only")
max_margin = (v["portrait_w"] - T["mobile_max_size"] * MIN) / 2
rows.append(f"phone: 8x8 {(v['portrait_w']-2*v['side_margin'])/8:.2f}px; max side margin for 8x8 = {max_margin:.1f}px")
check(v["side_margin"] <= max_margin, "phone side margin too large for 8x8")
# --- wide layout (Art mock desktop_wide_9x9: tray y 8..H-8, inner margin 12; board = H - 40)
def wide_board(W, H):
    vm = 2 * (w["tray_outer"] + w["tray_inner"]) if H >= w["compact_below_h"] else w["compact_total_v_margin"]
    b = H - vm; tray = b + 2 * w["tray_inner"]
    panel = W - w["tray_left"] - tray - 2 * w["panel_gap"]
    return b, panel
for W, H in w["check_viewports"]:
    b, panel = wide_board(W, H)
    cells = {n: b / n for n in range(5, 10)}
    rows.append(f"wide {W}x{H}: board {b}px, panel {panel}px, cells " + " ".join(f"{n}:{c:.2f}" for n, c in cells.items()))
    for n, c in cells.items(): check(c >= MIN, f"wide {W}x{H} {n}x{n} {c:.2f}px < {MIN}")
    check(panel >= w["panel_min_w"], f"wide {W}x{H} panel {panel}px < {w['panel_min_w']}")
    check(b / H >= 0.85, f"wide {W}x{H} board < 85% of height (TT-AC-52)")
b800, _ = wide_board(800, 450)
check(abs(b800 / 9 - 45.56) < 0.01, f"9x9 at 800x450 = {b800/9:.2f}, expected 45.56 (Art mock)")
rows.append(f"9x9 at 800x450 = {b800/9:.2f}px; max total vertical margin for 9x9 at 450 = {450-9*MIN}px")
PW, PH = w["phone_landscape"]; b, _ = wide_board(PW, PH)
check(b / T["mobile_max_size"] >= MIN, f"phone landscape {PW}x{PH} 8x8 {b/8:.2f}px < {MIN}")
check(b / 9 < MIN, "9x9 must not fit phone landscape (wide-only on desktop/embeds)")
rows.append(f"phone landscape {PW}x{PH}: 8x8 {b/8:.2f}px, 9x9 {b/9:.2f}px (refused)")
check(v["body_text_px"] >= v["label_text_px"] >= v["min_text_px"], "text size order")
check(v["min_button_h"] >= MIN, "button height < tap min")
# --- content
total = 0.0; bpc = T["boards_per_chapter"]; lo, hi = T["chapter_minutes_range"]; prev_max = 0; g4 = 0
tut = T["tutorial_board_s"]
check(tut["min"] <= tut["est"] <= tut["max"] <= 60, "tutorial_board_s must be min<=est<=max<=60 (TT:47)")
banned = [re.compile(b, re.I) for b in T["banned_user_text"]]
for ch in T["chapters"]:
    s, g = ch["sizes"], ch["grades"]
    check(len(s) == bpc and len(g) == bpc, f"ch{ch['id']} needs {bpc} boards")
    check(max(s) <= T["v1_content_max_size"], f"ch{ch['id']} uses a size above v1 content max")
    check(all(1 <= x <= T["max_grade"] for x in g), f"ch{ch['id']} grade out of range")
    check(max(s) >= prev_max, f"ch{ch['id']} max size decreases"); prev_max = max(s)
    g4 += g.count(4); check(g.count(4) <= 1, f"ch{ch['id']} has >1 grade-4 board")
    for i in range(len(g) - 1):
        check(not (g[i] >= 3 and g[i + 1] >= 3 and g[i] == max(g) == g[i + 1]), f"ch{ch['id']} two hardest boards in a row")
    for name in (ch["recipe"], ch["decor"]):
        for b_ in banned: check(not b_.search(name), f"ch{ch['id']} name '{name}' matches banned /{b_.pattern}/")
    tset = set(ch.get("tutorial", []))
    sec = sum(tut["est"] if (i + 1) in tset else T["median_solve_s"][str(n)] for i, n in enumerate(s))
    mins = sec / 60; total += mins; rows.append(f"ch{ch['id']}: {mins:.1f} min ({ch['recipe']})")
    check(lo <= mins <= hi, f"ch{ch['id']} {mins:.1f} min outside {lo}-{hi}")
check(T["chapters"][0]["sizes"] == [5] * bpc, "chapter 1 must be all 5x5")
# --- v1.1 structure: stars are a mastery mark (never time, never currency); level map numbers every chapter board
st = T["stars"]; lm = T["level_map"]
check(st["max_per_board"] == 3 and st["no_hint"] == 2 and st["no_hint_no_conflict"] == 3, "stars rule 1/2/3")
check(st["time_based"] is False and st["currency"] is False, "stars must not be time-based or a currency (D-09, D-16)")
check(lm["unlock"] == "sequential" and lm["button_px"] >= v["min_tap_px"], "level map unlock / tap size")
check(lm["cols_phone"] * lm["button_px"] + (lm["cols_phone"] - 1) * 8 <= v["portrait_w"] - 2 * v["side_margin"], "level map row fits the phone column")
check(bpc >= T["v102_boards_per_chapter"], "v1.1 keeps the v1.0.2 boards b1..b5")
rows.append(f"levels: {len(T['chapters']) * bpc} on the map, max stars {len(T['chapters']) * bpc * st['max_per_board']}")
# --- v1.2 cakes: one piece per chapter, all shipped as B2 @2x sprites; daily + debug pieces exist too
ck = T["cakes"]; board_dir = p.resolve().parent.parent / "assets" / "board"
check(len(ck["by_chapter"]) == len(T["chapters"]), "one cake per chapter")
check(len(set(ck["by_chapter"])) == len(ck["by_chapter"]) and ck["daily"] not in ck["by_chapter"], "chapter cakes distinct, daily cake separate")
if board_dir.is_dir():
    for c in ck["by_chapter"] + [ck["daily"], ck["debug"]]:
        check((board_dir / f"cake_{c}@2x.png").is_file(), f"missing sprite cake_{c}@2x.png")
check(ck["min_halo_coverage"] >= 0.98 and ck["min_ink_coverage"] >= 0.94, "cake readability floors")
check(total >= T["min_total_content_min"], f"total content {total:.1f} min < {T['min_total_content_min']}")
d = T["daily"]
check(d["pool"] >= 365, "daily pool < 1 year"); check(len(d["sizes_mon_to_sun"]) == 7, "daily weekday sizes")
check(max(d["sizes_mon_to_sun"]) <= T["v1_content_max_size"], "daily size above v1 content max")
check(dt.date.fromisoformat(d["epoch"]).weekday() == 0, "daily epoch must be a Monday")
# --- ads / hints / save / perf
a = T["ads"]; h = T["hints"]; sv = T["save"]; pf = T["perf"]
check(a["first_interstitial_after_chapter"] >= 1, "ads before chapter 1 ends")
check(a["rewarded_uses"] == ["hint"], "rewarded must be hint-only")
check(a["interstitial_after_daily"] is False, "no interstitial after daily")
check(a["min_session_s_before_interstitial"] >= 300 and a["min_gap_between_midgame_s"] >= 180, "U2 floors")
check(1 < a["level_break_every"] < T["boards_per_chapter"] and T["boards_per_chapter"] % a["level_break_every"] == 0, "level break must fall inside a chapter and line up with its end (v1.4)")
check(h["chapter1_unlimited_free"] and h["chapter1_free_on_replay"] and h["free_per_board"] >= 1, "hint allowance")
check(h["idle_pulse_s"] == 30 and h["idle_pulse_max_per_board"] == 1, "idle pulse tunables")
check(sv["key"] == "tea_bakery_save_v1" and sv["debounce_ms"] < sv["qa_tolerance_ms"], "save tunables")
check(pf["cpu_throttle"] >= 4 and pf["frame_p95_ms"] <= 33.4 and pf["tap_to_frame_p95_ms"] <= 100 and pf["long_task_ms"] <= 50, "perf (U3)")
# --- streak U1
D = dt.date.fromisoformat; ONE = dt.timedelta(1)
def streak(S, today):
    S = set(S)
    if not S: return 0
    T_ = max(today, max(S)); d_ = T_ if T_ in S else T_ - ONE
    count = 0; last_forgiven = None
    while True:
        if d_ in S: count += 1; d_ -= ONE; continue
        if (d_ - ONE) in S and (last_forgiven is None or (last_forgiven - d_).days >= d["forgiven_miss_min_gap_days"]):
            last_forgiven = d_; d_ -= ONE; continue
        return count
def best_total(S):
    S = sorted(set(S)); best = 0
    for i, x in enumerate(S): best = max(best, streak(S[:i + 1], x))
    return best, len(S)
for vec in V:
    S = [D(x) for x in vec["S"]]; got = streak(S, D(vec["today"]))
    check(got == vec["streak"], f"{vec['id']}: streak {got} != {vec['streak']}")
    if "best" in vec:
        b_, t_ = best_total(S); check((b_, t_) == (vec["best"], vec["total"]), f"{vec['id']}: best/total {b_}/{t_}")
    if vec.get("fresh_line"):
        prev = sorted(set(S))[:-1]; check(got == 1 and len(prev) >= 1, f"{vec['id']}: fresh-streak line condition")
# --- player-facing copy in the spec (TT-AC-39): §11 drafted copy + quoted UI/hint strings in §2/§4/§6/§7/§9/§16
def section(num):
    m = re.search(r"^## " + re.escape(num) + r"\.[^\n]*\n(.*?)(?=^## )", text, re.S | re.M); return m.group(1) if m else ""
copy = []
s11 = section("11"); k = s11.find("**DECIDED"); check(k >= 0, "§11 drafted copy block not found")
copy.append(("§11 portal/controls copy", s11[k:]))
for num in ("2", "4", "6", "7", "9", "16"):
    for line in section(num).splitlines():
        if "TT:" in line: continue            # Player Profile quotes are not player-facing
        for q in re.findall(r'"([^"\n]{3,})"', line): copy.append((f"§{num} string", q))
for where, t in copy:
    for b_ in banned:
        m = b_.search(t)
        check(not m, f"{where}: player-facing text matches banned /{b_.pattern}/ ('{m.group(0) if m else ''}')")
retired = [re.compile(r, re.I) for r in T.get("retired_mark_text", [])]
check(retired, "retired_mark_text missing (v1.0: the mark is an empty cake mold)")
for where, t in copy:
    for r_ in retired:
        m = r_.search(t)
        check(not m, f"{where}: player-facing text uses the retired X mark /{r_.pattern}/ ('{m.group(0) if m else ''}')")
check(re.search(r"empty mold", s11, re.I), "controls copy must describe the empty mold")
# --- D-02 rules text on phones (v1.0.2: <=3 lines at >=16 px; never <=2 lines, never <16 px)
d02 = re.search(r"^- \*\*D-02 rules wording[^\n]*", text, re.M)
check(d02 and "≤3 lines, ≥16 px" in d02.group(0), "D-02 must say phones: ≤3 lines, ≥16 px (v1.0.2)")
check(not re.search(r"≤\s*2 lines", text), "stale '≤2 lines' rules-text wording (v1.0.2 = ≤3 lines)")
rows.append("D-02 phones: ≤3 lines at ≥16 px")
# --- AC bookkeeping (v1.0: 53 ACs = 50 gating + 3 post-launch in §13.3)
ac_ids = sorted(set(int(x) for x in re.findall(r"\*\*TT-AC-(\d+)\*\*", text)))
check(ac_ids == list(range(1, len(ac_ids) + 1)), f"AC ids not contiguous: {ac_ids}")
m3 = re.search(r"^### 13\.3[^\n]*\n(.*?)(?=^## )", text, re.S | re.M)
post_ids = sorted(int(x) for x in re.findall(r"\*\*TT-AC-(\d+)\*\*", m3.group(1))) if m3 else []
check(post_ids == [34, 35, 36], f"post-launch ACs should be 34-36, got {post_ids}")
check(not re.search(r"\bheart", text, re.I), "no heart references (no fail state, Shahar Q3)")
rows.append(f"ACs: {len(ac_ids)} total = {len(ac_ids)-len(post_ids)} gating + {len(post_ids)} post-launch")
check("{{TITLE}}" in s11, "§11 portal copy must use the literal {{TITLE}} placeholder")
rows.append(f"player-facing copy scanned: {len(copy)} strings/blocks against {len(banned)} banned patterns")
rows.append(f"streak vectors: {len(V)} checked")
rows.append(f"total chapter content: {total:.1f} min; {bpc*len(T['chapters'])} boards; grade-4 boards: {g4}")
print("\n".join(rows))
if fails:
    print("FAIL:\n- " + "\n- ".join(fails)); sys.exit(1)
print("PASS spec_assert (%d chapters, %d streak vectors)" % (len(T["chapters"]), len(V)))
