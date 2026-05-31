#!/bin/bash
# Rebuild AppImages with iter30 source + rename all dist artifacts with date
set -e
DATE=$(date +%Y%m%d)
echo "Release date stamp: $DATE"

DIST=/mnt/d/03_game_tmp/eob1_cht/dist
BUILD=/root/EOB1-CHT-build

# === Rebuild AppImages with current iter30 binaries ===
echo ""
echo "=== Rebuilding AppImages with iter30 ==="
SCUMM_15=$BUILD/scummvm-15
SCUMM_16=$BUILD/scummvm-16

# Stage iter30 Linux scummvm (15-tall is current source state)
strip -o "$SCUMM_15" /tmp/eob_test/scummvm
echo "scummvm-15: $(stat -c '%s bytes' $SCUMM_15)"

# Build 16-tall Linux variant
LIN=/root/scummvm_work/scummvm
F=engines/kyra/graphics/screen_eob.cpp
cp "$LIN/$F" "$LIN/${F}.iter30"
sed -i 's|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 15 : 14);|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 16 : 14);|' "$LIN/$F"
cd "$LIN" && make -j8 engines/kyra/graphics/screen_eob.o >/dev/null 2>&1
make -j8 >/dev/null 2>&1
strip -o "$SCUMM_16" "$LIN/scummvm"
cp "$LIN/${F}.iter30" "$LIN/$F"
rm "$LIN/${F}.iter30"
make -j8 engines/kyra/graphics/screen_eob.o >/dev/null 2>&1
make -j8 >/dev/null 2>&1  # restore 15-tall master
echo "scummvm-16: $(stat -c '%s bytes' $SCUMM_16)"

APPRUN_CONTENT='#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
GAMEDIR="$HERE/game"
exec "$HERE/usr/bin/scummvm" --extrapath="$GAMEDIR" --path="$GAMEDIR" --auto-detect "$@"
'

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

build_appimage() {
    local SUFFIX=$1
    local SCUMM_BIN=$2
    local SRC_GAME=$3
    APPDIR="$BUILD/EOB1-CHT-${SUFFIX}.AppDir"
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps" "$APPDIR/game"
    cp "$SCUMM_BIN" "$APPDIR/usr/bin/scummvm"
    chmod +x "$APPDIR/usr/bin/scummvm"
    cp -r "$SRC_GAME/." "$APPDIR/game/"
    echo "$APPRUN_CONTENT" > "$APPDIR/AppRun"
    chmod +x "$APPDIR/AppRun"
    cat > "$APPDIR/EOB1-CHT-${SUFFIX}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=EOB1 CHT ${SUFFIX}
Name[zh_TW]=魔眼殺機 1 繁中 (${SUFFIX} 字模)
Comment=Eye of the Beholder 1 Traditional Chinese fan translation
Exec=AppRun
Icon=eob1-cht-${SUFFIX}
Categories=Game;RolePlaying;
Terminal=false
EOF
    cp "$APPDIR/EOB1-CHT-${SUFFIX}.desktop" "$APPDIR/usr/share/applications/"
    python3 -c "$ICON_PY" > "$APPDIR/eob1-cht-${SUFFIX}.png"
    ln -sf "eob1-cht-${SUFFIX}.png" "$APPDIR/.DirIcon"
    cp "$APPDIR/eob1-cht-${SUFFIX}.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
    cd "$BUILD"
    OUT="$DIST/EOB1-CHT-${SUFFIX}-${DATE}-x86_64.AppImage"
    ARCH=x86_64 ./appimagetool --no-appstream "$APPDIR" "$OUT" 2>&1 | tail -2
    sha256sum "$OUT"
}

build_appimage "15x15" "$SCUMM_15" "$DIST/EOB1-CHT-15x15/game"
build_appimage "16x16" "$SCUMM_16" "$DIST/EOB1-CHT-16x16/game"

# === Rename Win64 ZIPs with date ===
echo ""
echo "=== Rename Win64 ZIPs with date ==="
mv "$DIST/EOB1-CHT-15x15-Win64.zip" "$DIST/EOB1-CHT-15x15-${DATE}-Win64.zip"
mv "$DIST/EOB1-CHT-16x16-Win64.zip" "$DIST/EOB1-CHT-16x16-${DATE}-Win64.zip"

# === Cleanup old undated AppImages ===
echo ""
echo "=== Cleanup old undated AppImages ==="
rm -f "$DIST/EOB1-CHT-15x15-x86_64.AppImage" \
      "$DIST/EOB1-CHT-16x16-x86_64.AppImage" \
      "$DIST/EOB1-CHT-x86_64.AppImage"

# === Final inventory ===
echo ""
echo "=== Final dated dist ==="
ls -la "$DIST"/EOB1-CHT-* | grep -v ".AppDir" | head -10
echo ""
echo "=== SHA256 ==="
sha256sum "$DIST"/EOB1-CHT-*${DATE}* 2>&1
