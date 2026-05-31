"""Build iter12-era ceob.pat: EOB2 CHINFONT.FNT 14-tall cropped to 12-tall.
For iter17 diagnostic — pair with iter15 binary + engine reverted to load 12.
"""
import struct
from pathlib import Path

EOB2 = "/mnt/e/dos1866/eob2/CHINFONT.FNT"
OUT = Path("/mnt/d/03_game_tmp/eob1_cht/test-reports/font-preview/ceob_iter12era.pat")

HEIGHT = 12
WIDTH = 16
TOP_TRIM = 1  # iter12 EOB2 crop: rows 1..12

def main():
    data = Path(EOB2).read_bytes()
    assert len(data) % 30 == 0
    glyphs = {}
    for i in range(len(data) // 30):
        b = data[i*30:(i+1)*30]
        lo, hi = b[0], b[1]
        cp = (hi << 8) | lo
        if not (cp & 0x8000) or cp in glyphs: continue
        dec = bytearray(28)
        for k in range(28):
            dec[k] = b[2+k] ^ (lo if k % 2 == 0 else hi)
        cropped = bytearray()
        for r in range(TOP_TRIM, TOP_TRIM + HEIGHT):
            cropped += dec[r*2:r*2+2]
        glyphs[cp] = bytes(cropped)

    out = bytearray()
    for cp in sorted(glyphs):
        out += struct.pack(">H", cp)
        out += glyphs[cp]
    out += b"\xff\xff"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(out)
    print(f"Wrote {OUT}: {len(out)} bytes, {len(glyphs)} glyphs")

if __name__ == "__main__":
    main()
