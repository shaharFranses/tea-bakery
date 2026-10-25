#!/usr/bin/env python3
"""Godot 4.3 pck reader shared by the release audit and the user-text scan (pattern: sudoku-dash qa/release_audit.sh).
files(pck) -> [(res_path, raw_bytes)]; .gdc (binary tokens) are zstd-decompressed and their identifier table, stored as
UTF-32 code points XOR 0xB6, is decoded too, so identifiers like hook names are greppable (string constants are UTF-8).
Needs `zstandard` (venv /workspace/zvenv: python3 -m venv /workspace/zvenv && /workspace/zvenv/bin/pip install zstandard)."""
import struct
try:
    import zstandard
except ImportError:
    zstandard = None

def files(path):
    b = open(path, "rb").read(); assert b[:4] == b"GDPC", "not a Godot pck"
    o = 4; ver, ma, mi, pa, flags = struct.unpack_from("<5I", b, o); o += 20; base = struct.unpack_from("<Q", b, o)[0]; o += 8 + 64
    n = struct.unpack_from("<I", b, o)[0]; o += 4; out = []
    for _ in range(n):
        l = struct.unpack_from("<I", b, o)[0]; o += 4; p = b[o:o + l].rstrip(b"\0").decode(); o += l
        off, sz = struct.unpack_from("<QQ", b, o); o += 16 + 16 + 4
        out.append((p, b[base + off: base + off + sz]))
    return (ma, mi, pa), out

def text_of(path, data):
    """Searchable bytes for one pck entry: raw + (for .gdc) decompressed + XOR-0xB6 UTF-32 decoded identifiers."""
    parts = [data]
    if path.endswith(".gdc") and data[:4] == b"GDSC":
        v, dsz = struct.unpack_from("<II", data, 4)
        body = data[12:]
        if dsz:
            if zstandard is None: raise SystemExit("pck_strings: zstandard missing (see module doc)")
            body = zstandard.ZstdDecompressor().decompress(body, max_output_size=dsz)
        parts.append(body)
        for a in range(4):
            chars = []
            for i in range(a, len(body) - 3, 4):
                c = struct.unpack_from("<I", body, i)[0] ^ 0xB6
                chars.append(chr(c) if 32 <= c < 127 else "\n")
            parts.append("".join(chars).encode())
    return b"\n".join(parts)
