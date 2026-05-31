#!/bin/bash
# iter30: full bounds-check audit + KYRA.DAT regen with _patternSuffix[2]
set -e
SRC=/mnt/d/03_game_tmp/eob1_cht/scummvm-source
LIN=/root/scummvm_work/scummvm
WIN=/root/scummvm_work/scummvm-win64-build

for f in engines/kyra/engine/items_eob.cpp; do
    cp "$SRC/$f" "$LIN/$f"
    cp "$SRC/$f" "$WIN/$f"
    echo "synced $f (both)"
done

# chinese.h only synced to Linux clone (devtools)
cp "$SRC/devtools/create_kyradat/resources/eob1_dos_chinese.h" \
   "$LIN/devtools/create_kyradat/resources/eob1_dos_chinese.h"
echo "synced eob1_dos_chinese.h (Linux only)"

echo ""
echo "=== rebuild create_kyradat ==="
cd "$LIN" && make -j8 devtools/create_kyradat/create_kyradat 2>&1 | tail -3

echo ""
echo "=== regen KYRA.DAT ==="
cd "$LIN/devtools/create_kyradat" && ./create_kyradat /tmp/kyra_iter30 2>&1 | tail -3
cp /tmp/kyra_iter30 /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT

echo ""
echo "=== build Win scummvm ==="
cd "$WIN" && make -j8 2>&1 | tail -3
cp "$WIN/scummvm.exe" /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe

echo ""
echo "=== build Linux scummvm ==="
cd "$LIN" && make -j8 2>&1 | tail -3
cp "$LIN/scummvm" /tmp/eob_test/scummvm

echo ""
echo "=== Deploy to all dist folders ==="
DIST=/mnt/d/03_game_tmp/eob1_cht/dist
# Strip Linux scummvm for AppImage
strip -o /tmp/scummvm-15-stripped /tmp/eob_test/scummvm

# Update Win dist (engine load 15)
cp "$WIN/scummvm.exe" "$DIST/EOB1-CHT-15x15/scummvm.exe"
cp /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT "$DIST/EOB1-CHT-15x15/game/KYRA.DAT"

# For 16x16 dist: rebuild Win with engine 16
F=engines/kyra/graphics/screen_eob.cpp
cp "$WIN/$F" "$WIN/${F}.iter30"
sed -i 's|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 15 : 14);|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 16 : 14);|' "$WIN/$F"
echo "patched engine 15→16"
cd "$WIN" && make -j8 engines/kyra/graphics/screen_eob.o 2>&1 | tail -3
make -j8 2>&1 | tail -3
cp "$WIN/scummvm.exe" "$DIST/EOB1-CHT-16x16/scummvm.exe"
cp /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT "$DIST/EOB1-CHT-16x16/game/KYRA.DAT"
# Restore source
cp "$WIN/${F}.iter30" "$WIN/$F"
rm "$WIN/${F}.iter30"
# Rebuild master to 15
cd "$WIN" && make -j8 engines/kyra/graphics/screen_eob.o >/dev/null 2>&1
make -j8 >/dev/null 2>&1

echo ""
echo "=== Repack ZIPs ==="
cd "$DIST"
for VER in 15x15 16x16; do
    OUT="EOB1-CHT-$VER-Win64.zip"
    rm -f "$OUT"
    cd "EOB1-CHT-$VER"
    zip -r9 "$DIST/$OUT" . -x "*.bak" "*.backup" 2>&1 | tail -3
    cd "$DIST"
done

echo ""
echo "=== Final SHAs ==="
sha256sum "$DIST"/EOB1-CHT-*Win64.zip \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT
