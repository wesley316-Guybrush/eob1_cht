"""Build ceob.pat from Unifont 16x16, covering ALL valid Big5 codepoints
(not just those in EOB2 CHINFONT.FNT — that was the iter13 gap).

cp950 Big5 ranges:
  lead 0xA1-0xFE
  trail 0x40-0x7E or 0xA1-0xFE

Output: prefixed-raw format with height=16 for loadPrefixedRaw(f, 16).
"""
import struct
from pathlib import Path
import freetype

UNIFONT  = "/usr/share/fonts/truetype/unifont/unifont.ttf"
OUT_PAT  = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat")

WIDTH  = 16
HEIGHT = 16


def render_glyph(face, ucp):
    """Render at Unifont native 16x16. Returns 32 bytes or None."""
    try:
        face.load_char(
            ucp,
            freetype.FT_LOAD_RENDER
            | freetype.FT_LOAD_MONOCHROME
            | freetype.FT_LOAD_TARGET_MONO,
        )
    except Exception:
        return None
    bm = face.glyph.bitmap
    if bm.width == 0 or bm.rows == 0:
        return None
    out = bytearray(2 * HEIGHT)
    for r in range(min(bm.rows, HEIGHT)):
        row_bits = 0
        for c in range(min(bm.width, WIDTH)):
            src_byte = bm.buffer[r * bm.pitch + c // 8]
            if src_byte & (0x80 >> (c % 8)):
                row_bits |= (0x8000 >> c)
        out[r * 2]     = (row_bits >> 8) & 0xFF
        out[r * 2 + 1] = row_bits & 0xFF
    return bytes(out) if any(out) else None


def cp_to_unicode(cp):
    """Big5 codepoint -> unicode int via cp950."""
    if cp < 0x100:
        return cp
    try:
        return ord(bytes([cp >> 8, cp & 0xFF]).decode("cp950"))
    except Exception:
        return None


def main():
    face = freetype.Face(UNIFONT)
    face.set_pixel_sizes(0, 16)
    print(f"Unifont loaded; building ceob.pat ALL Big5 -> 16x16")

    out = bytearray()
    n_written = 0
    n_unicode_fail = 0
    n_render_fail = 0

    # Iterate ALL Big5 codepoints (lead 0xA1-0xFE, trail 0x40-0x7E + 0xA1-0xFE)
    for lead in range(0xA1, 0xFF):
        for trail in list(range(0x40, 0x7F)) + list(range(0xA1, 0xFF)):
            cp = (lead << 8) | trail
            ucp = cp_to_unicode(cp)
            if ucp is None:
                n_unicode_fail += 1
                continue
            bm = render_glyph(face, ucp)
            if bm is None:
                n_render_fail += 1
                continue
            out += struct.pack(">H", cp)
            out += bm
            n_written += 1

    out += b"\xff\xff"
    OUT_PAT.write_bytes(out)
    print(f"Wrote {OUT_PAT}: {len(out)} bytes")
    print(f"  Glyphs written:        {n_written}")
    print(f"  cp950 decode failures: {n_unicode_fail}")
    print(f"  Render failures:       {n_render_fail}")

    # Spot-check problem codepoints from CAMP menu
    print("\n=== Spot check problem chars ===")
    for ch, name in [("：", "FULL-WIDTH COLON"),
                     ("憶", "YI memory"),
                     ("營", "YING camp"),
                     ("記", "JI record"),
                     ("法", "FA law/magic"),
                     ("術", "SHU technique"),
                     ("選", "XUAN choose"),
                     ("？", "FULL-WIDTH QUESTION MARK")]:
        try:
            cp_bytes = ch.encode("cp950")
            if len(cp_bytes) == 2:
                cp = (cp_bytes[0] << 8) | cp_bytes[1]
                ucp = ord(ch)
                bm = render_glyph(face, ucp)
                status = "OK" if bm else "MISSING"
                print(f"  {ch} ({name}) cp950=0x{cp:04X} U+{ucp:04X}: {status}")
            else:
                print(f"  {ch} ({name}): not cp950 2-byte")
        except Exception as e:
            print(f"  {ch} ({name}): error {e}")


if __name__ == "__main__":
    main()
