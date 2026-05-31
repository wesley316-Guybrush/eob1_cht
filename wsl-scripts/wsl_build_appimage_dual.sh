#!/bin/bash
# iter28: Build EOB1 CHT AppImage in 2 variants: 15×15 + 16×16
# Each AppImage is self-contained: stripped scummvm + game files + ceob.pat at chosen size.
set -e

BUILD=/root/EOB1-CHT-build
DIST=/mnt/d/03_game_tmp/eob1_cht/dist
SRC=/mnt/d/03_game_tmp/eob1_cht/scummvm-source
LIN=/root/scummvm_work/scummvm

mkdir -p "$BUILD"
mkdir -p "$DIST"

# Check appimagetool present
if [ ! -x "$BUILD/appimagetool" ]; then
    echo "FATAL: $BUILD/appimagetool not found. Download from"
    echo "  https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    exit 1
fi

# ============================================================
# Build TWO Linux scummvm binaries: one for engine load 15, one for 16
# ============================================================
F=engines/kyra/graphics/screen_eob.cpp
cp "$LIN/$F" "$LIN/${F}.iter26"   # backup current (15)

# === Build 15-tall (current source) ===
echo "=== Build Linux scummvm-15 ==="
cd "$LIN" && make -j8 2>&1 | tail -3
SCUMM_15=$BUILD/scummvm-15
strip -o "$SCUMM_15" "$LIN/scummvm"
echo "scummvm-15: $(stat -c '%s bytes' $SCUMM_15)"

# === Patch to 16 and rebuild ===
echo ""
echo "=== Patch engine to 16 ==="
sed -i 's|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 15 : 14);|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 16 : 14);|' "$LIN/$F"
grep -n "loadPrefixedRaw(f," "$LIN/$F" | head -1

echo ""
echo "=== Build Linux scummvm-16 ==="
cd "$LIN" && make -j8 engines/kyra/graphics/screen_eob.o 2>&1 | tail -3
make -j8 2>&1 | tail -3
SCUMM_16=$BUILD/scummvm-16
strip -o "$SCUMM_16" "$LIN/scummvm"
echo "scummvm-16: $(stat -c '%s bytes' $SCUMM_16)"

# Restore source
cp "$LIN/${F}.iter26" "$LIN/$F"
rm "$LIN/${F}.iter26"

# ============================================================
# Build AppDir for each variant
# ============================================================

# Shared AppRun launcher (uses bundled game/)
APPRUN_CONTENT='#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
GAMEDIR="$HERE/game"
if [ ! -f "$GAMEDIR/EOB.EXE" ]; then
    echo "EOB1 game data not found in $GAMEDIR"
    exit 1
fi
exec "$HERE/usr/bin/scummvm" --extrapath="$GAMEDIR" --path="$GAMEDIR" --auto-detect "$@"
'

# Shared icon generator (256x256 dark blue solid PNG via zlib)
ICON_PY='
import struct, zlib, sys
W, H = 256, 256
raw = bytearray()
for y in range(H):
    raw.append(0)
    for x in range(W):
        raw += bytes([0x1a, 0x2b, 0x4c])
idat = zlib.compress(bytes(raw), 9)
def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
png  = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", idat)
png += chunk(b"IEND", b"")
sys.stdout.buffer.write(png)
'

# Build a single AppImage given variant suffix + scummvm binary + dist source folder
build_variant() {
    local SUFFIX=$1     # "15x15" or "16x16"
    local SCUMM_BIN=$2  # path to stripped scummvm
    local SRC_GAME=$3   # path to source game/ dir (with correct ceob.pat)

    APPDIR="$BUILD/EOB1-CHT-${SUFFIX}.AppDir"
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps" "$APPDIR/game"

    # Install stripped scummvm
    cp "$SCUMM_BIN" "$APPDIR/usr/bin/scummvm"
    chmod +x "$APPDIR/usr/bin/scummvm"

    # Bundle game files (including correct ceob.pat)
    cp -r "$SRC_GAME/." "$APPDIR/game/"

    # AppRun
    echo "$APPRUN_CONTENT" > "$APPDIR/AppRun"
    chmod +x "$APPDIR/AppRun"

    # Desktop entry
    cat > "$APPDIR/EOB1-CHT-${SUFFIX}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=EOB1 CHT ${SUFFIX}
Name[zh_TW]=魔眼殺機 1 繁中 (${SUFFIX} 字模)
Comment=Eye of the Beholder 1 Traditional Chinese fan translation (${SUFFIX} font)
Exec=AppRun
Icon=eob1-cht-${SUFFIX}
Categories=Game;RolePlaying;
Terminal=false
EOF
    cp "$APPDIR/EOB1-CHT-${SUFFIX}.desktop" "$APPDIR/usr/share/applications/"

    # Icon
    python3 -c "$ICON_PY" > "$APPDIR/eob1-cht-${SUFFIX}.png"
    ln -sf "eob1-cht-${SUFFIX}.png" "$APPDIR/.DirIcon"
    cp "$APPDIR/eob1-cht-${SUFFIX}.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"

    # Build AppImage
    cd "$BUILD"
    OUT="$DIST/EOB1-CHT-${SUFFIX}-x86_64.AppImage"
    ARCH=x86_64 ./appimagetool --no-appstream "$APPDIR" "$OUT" 2>&1 | tail -3
    echo ""
    ls -la "$OUT"
    sha256sum "$OUT"
}

# ============================================================
# Build 15×15 AppImage (uses dist/EOB1-CHT-15x15/game with 15-tall ceob.pat)
# ============================================================
echo ""
echo "##############################"
echo "# Build 15×15 AppImage"
echo "##############################"
build_variant "15x15" "$SCUMM_15" "/mnt/d/03_game_tmp/eob1_cht/dist/EOB1-CHT-15x15/game"

# ============================================================
# Build 16×16 AppImage (uses dist/EOB1-CHT-16x16/game with 16-tall ceob.pat)
# ============================================================
echo ""
echo "##############################"
echo "# Build 16×16 AppImage"
echo "##############################"
build_variant "16x16" "$SCUMM_16" "/mnt/d/03_game_tmp/eob1_cht/dist/EOB1-CHT-16x16/game"

echo ""
echo "=== Final AppImages ==="
ls -la "$DIST"/EOB1-CHT-*-x86_64.AppImage
echo ""
echo "=== SHA256 ==="
sha256sum "$DIST"/EOB1-CHT-*-x86_64.AppImage
