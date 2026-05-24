"""Build 15×15 ceob.pat (active) from Unifont 16×16 bicubic resample.
Glyph in 16-wide cell at cols 0..14, col 15 zero (1-px right gap).
Output 15-row prefixed-raw, engine load = 15.
"""
import struct
from pathlib import Path
from PIL import Image

SRC = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_16tall.pat.bak")
DST = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat")
BAK = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_14x14.pat.bak")

SRC_W = 16; SRC_H = 16
DST_VIS_W = 15; DST_H = 15
CELL_W = 16
THRESHOLD = 110

def bm_to_img(bm):
    img = Image.new("L", (SRC_W, SRC_H), 0)
    px = img.load()
    for r in range(SRC_H):
        b = (bm[r*2] << 8) | bm[r*2+1]
        for c in range(SRC_W):
            if b & (0x8000 >> c):
                px[c, r] = 255
    return img

def img_to_bm(img, thr=THRESHOLD):
    px = img.load()
    out = bytearray(2 * DST_H)
    for r in range(DST_H):
        bits = 0
        for c in range(DST_VIS_W):
            if px[c, r] >= thr:
                bits |= (0x8000 >> c)
        out[r*2]     = (bits >> 8) & 0xFF
        out[r*2 + 1] = bits & 0xFF
    return bytes(out)

def main():
    # Backup current (iter24 14×14)
    if DST.exists() and not BAK.exists():
        BAK.write_bytes(DST.read_bytes())
        print(f"Backed up 14×14 to {BAK}")
    data = SRC.read_bytes()
    out = bytearray()
    i = 0; n = 0
    while i + 2 <= len(data):
        cp = (data[i] << 8) | data[i+1]
        if cp == 0xFFFF: break
        i += 2
        bm = data[i:i + 2*SRC_H]
        i += 2*SRC_H
        si = bm_to_img(bm)
        di = si.resize((DST_VIS_W, DST_H), Image.BICUBIC)
        out += struct.pack(">H", cp)
        out += img_to_bm(di)
        n += 1
    out += b"\xff\xff"
    DST.write_bytes(out)
    print(f"Wrote {DST}: {len(out)} bytes, {n} glyphs at 15×15 (resample, thr={THRESHOLD})")

if __name__ == "__main__":
    main()
