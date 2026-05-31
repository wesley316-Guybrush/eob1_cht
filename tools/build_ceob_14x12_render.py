"""Build 14×12 ceob.pat by REAL TTF rasterization (not mask/crop).

Source: AR PL Mingti2L Big5 TTF (or fallback to Droid Sans Fallback).
Renders each CJK glyph at 12px pixel height with monochrome bitmap output,
centered within 16-wide engine cell with 1 px left + 1 px right padding
so visual glyph width = 14.

Output: ceob.pat with 12-row prefixed-raw format. Engine load = 12.
"""
import struct
from pathlib import Path
import freetype

# Candidate fonts in order of preference
FONT_CANDIDATES = [
    "/usr/share/fonts/truetype/arphic-bsmi00lp/bsmi00lp.ttf",   # AR PL Mingti2L Big5 - best for traditional Chinese
    "/usr/share/fonts/truetype/arphic/uming.ttc",                # AR PL UMing TW
    "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf", # Droid Sans Fallback
    "/usr/share/fonts/truetype/unifont/unifont.ttf",             # Unifont (last resort)
]

DST_PAT = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat")
BAK = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_14tall.pat.bak")

CELL_W = 16   # engine cell width (hardcoded in big5.h)
VIS_W  = 14   # visible glyph width inside cell
HEIGHT = 12

X_OFFSET = (CELL_W - VIS_W) // 2  # = 1, center horizontally


def pick_font():
    for f in FONT_CANDIDATES:
        if Path(f).exists():
            print(f"Using font: {f}")
            return f
    raise RuntimeError("No CJK font found")


def render_glyph(face, ucp):
    """Render a unicode codepoint to a 16×12 bitmap (visible 14×12 centered).
    Returns 2*HEIGHT bytes or None."""
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

    # Glyph metrics: face.glyph.bitmap_top is the offset from baseline to top of bitmap
    # We want to fit the glyph within HEIGHT rows
    # bm.rows is the actual rendered height (might be < HEIGHT or > HEIGHT)

    out = bytearray(2 * HEIGHT)

    # Vertical: center the rendered bitmap within HEIGHT rows
    # FreeType renders glyphs with their natural metrics; for CJK at 12px the
    # glyph typically fills almost the whole 12 rows. Use bitmap_top to anchor.
    # For simplicity: top-align with small adjustment based on bitmap_top
    bt = face.glyph.bitmap_top
    # bitmap_top is typically ~10-11 for full-height CJK at 12px
    # Try: y_offset = HEIGHT - bt (so baseline ~ row HEIGHT-1)
    y_offset = max(0, HEIGHT - bt - 1)
    if bm.rows + y_offset > HEIGHT:
        y_offset = max(0, HEIGHT - bm.rows)

    # Horizontal: center the bitmap within VIS_W, with X_OFFSET left padding
    bl = face.glyph.bitmap_left
    # bitmap_left is offset from cursor origin. For monospace CJK at 12px,
    # typically 0 or 1. Center within VIS_W.
    x_offset = X_OFFSET + max(0, (VIS_W - bm.width) // 2)
    if bm.width + x_offset > CELL_W:
        x_offset = max(0, CELL_W - bm.width)

    # Copy pixels
    for r in range(min(bm.rows, HEIGHT - y_offset)):
        dst_r = r + y_offset
        if dst_r >= HEIGHT:
            break
        for c in range(min(bm.width, CELL_W - x_offset)):
            dst_c = c + x_offset
            if dst_c >= CELL_W:
                break
            src_byte = bm.buffer[r * bm.pitch + c // 8]
            if src_byte & (0x80 >> (c % 8)):
                # Set bit in output: row dst_r, col dst_c
                # Output: 2 bytes per row, MSB first
                if dst_c < 8:
                    out[dst_r * 2] |= (0x80 >> dst_c)
                else:
                    out[dst_r * 2 + 1] |= (0x80 >> (dst_c - 8))

    return bytes(out) if any(out) else None


def cp_to_unicode(cp):
    if cp < 0x100:
        return cp
    try:
        return ord(bytes([cp >> 8, cp & 0xFF]).decode("cp950"))
    except Exception:
        return None


def main():
    # Backup current ceob.pat
    if DST_PAT.exists() and not BAK.exists():
        BAK.write_bytes(DST_PAT.read_bytes())
        print(f"Backed up current to {BAK}")

    font_path = pick_font()
    face = freetype.Face(font_path)
    face.set_pixel_sizes(0, HEIGHT)  # 12-px tall

    out = bytearray()
    n_written = 0
    n_skipped = 0

    for lead in range(0xA1, 0xFF):
        for trail in list(range(0x40, 0x7F)) + list(range(0xA1, 0xFF)):
            cp = (lead << 8) | trail
            ucp = cp_to_unicode(cp)
            if ucp is None:
                n_skipped += 1
                continue
            bm = render_glyph(face, ucp)
            if bm is None:
                n_skipped += 1
                continue
            out += struct.pack(">H", cp)
            out += bm
            n_written += 1

    out += b"\xff\xff"
    DST_PAT.write_bytes(out)
    print(f"\nWrote {DST_PAT}: {len(out)} bytes, {n_written} glyphs at {VIS_W}×{HEIGHT}")
    print(f"  Skipped: {n_skipped}")

    # Spot-check important chars
    print("\n=== Spot check ===")
    for ch in "中止施法偵測魔的一是了能":
        try:
            cp_bytes = ch.encode("cp950")
            if len(cp_bytes) == 2:
                cp = (cp_bytes[0] << 8) | cp_bytes[1]
                ucp = ord(ch)
                bm = render_glyph(face, ucp)
                status = "OK" if bm else "MISSING"
                print(f"  {ch}  cp950=0x{cp:04X}  U+{ucp:04X}: {status}")
        except Exception as e:
            print(f"  {ch}: ERROR {e}")


if __name__ == "__main__":
    main()
