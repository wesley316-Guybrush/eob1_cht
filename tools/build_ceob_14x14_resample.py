"""Build 14×14 ceob.pat by REAL resampling of Unifont 16×16 source.

Method: PIL bicubic resize 16x16 → 14x14 + threshold (NOT mask/crop).
Preserves stroke topology by smoothing then re-binarizing.

Output: 14-row prefixed-raw with glyph in cols 0..13 of 16-wide cell,
cols 14..15 = 0 (2-px right gap). Engine load = 14.
"""
import struct
from pathlib import Path
from PIL import Image

SRC = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_16tall.pat.bak")
DST = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat")
BAK = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_12x12_render.pat.bak")

SRC_W = 16
SRC_H = 16
DST_VIS_W = 14
DST_H = 14
CELL_W = 16   # engine cell width (hardcoded)

# Threshold for binarization after resample
# Lower = thicker strokes (more pixels lit)
# Higher = thinner strokes (fewer pixels lit)
THRESHOLD = 110


def src_bm_to_image(bm):
    """16-byte/row * 16 rows -> grayscale Image 16x16."""
    img = Image.new("L", (SRC_W, SRC_H), 0)
    px = img.load()
    for r in range(SRC_H):
        b = (bm[r*2] << 8) | bm[r*2+1]
        for c in range(SRC_W):
            if b & (0x8000 >> c):
                px[c, r] = 255
    return img


def image_to_dst_bm(img, threshold=THRESHOLD):
    """14x14 grayscale Image -> bytes for 16-wide cell × DST_H rows.
    Glyph in cols 0..13, cols 14..15 zero."""
    px = img.load()
    out = bytearray(2 * DST_H)
    for r in range(DST_H):
        bits = 0
        for c in range(DST_VIS_W):
            if px[c, r] >= threshold:
                bits |= (0x8000 >> c)
        out[r*2]     = (bits >> 8) & 0xFF
        out[r*2 + 1] = bits & 0xFF
    return bytes(out)


def resample_glyph(bm):
    src_img = src_bm_to_image(bm)
    dst_img = src_img.resize((DST_VIS_W, DST_H), Image.BICUBIC)
    return image_to_dst_bm(dst_img)


def main():
    # Backup current (iter23 12x12)
    cur = DST
    if cur.exists() and not BAK.exists():
        BAK.write_bytes(cur.read_bytes())
        print(f"Backed up current 12×12 to {BAK}")

    print(f"Reading {SRC} (Unifont 16×16)...")
    data = SRC.read_bytes()
    print(f"  Size: {len(data)} bytes")

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
        new_bm = resample_glyph(bm)
        out += struct.pack(">H", cp)
        out += new_bm
        n += 1
    out += b"\xff\xff"
    DST.write_bytes(out)
    print(f"\nWrote {DST}: {len(out)} bytes, {n} glyphs at {DST_VIS_W}×{DST_H} (resampled bicubic)")
    print(f"Threshold: {THRESHOLD} (lower=thicker, higher=thinner)")


if __name__ == "__main__":
    main()
