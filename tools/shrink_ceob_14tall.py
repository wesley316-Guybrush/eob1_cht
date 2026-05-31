"""Shrink current 16-tall Unifont ceob.pat to 14-tall by dropping bottom 2 rows.
Engine load must be changed to 14 to match. Reduces visible glyph height ~12.5%.
"""
import struct
from pathlib import Path

SRC = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat")
DST = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat")
BAK = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_16tall.pat.bak")

SRC_H = 16
DST_H = 14

# Backup current
BAK.write_bytes(SRC.read_bytes())
print(f"Backed up current 16-tall to {BAK}")

data = SRC.read_bytes()
out = bytearray()
i = 0
n = 0
while i + 2 <= len(data):
    cp = (data[i] << 8) | data[i+1]
    if cp == 0xFFFF:
        break
    i += 2
    bm = data[i:i + 2*SRC_H]
    i += 2*SRC_H
    # Drop bottom 2 rows (rows 14, 15)
    cropped = bm[:2*DST_H]
    out += struct.pack(">H", cp)
    out += cropped
    n += 1
out += b"\xff\xff"
DST.write_bytes(out)
print(f"Wrote {DST}: {len(out)} bytes, {n} glyphs at {DST_H}-tall")
