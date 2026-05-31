#!/bin/bash
# iter23: TTF-rendered 14x12 ceob.pat + engine load 12 + 鐵糧→乾糧 string fix
set -e

SRC=/mnt/d/03_game_tmp/eob1_cht/scummvm-source
LIN=/root/scummvm_work/scummvm
WIN=/root/scummvm_work/scummvm-win64-build

# Sync screen_eob.cpp to both clones
for D in "$LIN" "$WIN"; do
    cp "$SRC/engines/kyra/graphics/screen_eob.cpp" "$D/engines/kyra/graphics/screen_eob.cpp"
done
echo "synced screen_eob.cpp"

# Sync the chinese.h to Linux only (only Linux build has devtools)
cp "$SRC/devtools/create_kyradat/resources/eob1_dos_chinese.h" "$LIN/devtools/create_kyradat/resources/eob1_dos_chinese.h"
echo "synced eob1_dos_chinese.h (Linux only)"

# Build create_kyradat
echo ""
echo "=== build create_kyradat ==="
cd "$LIN/devtools/create_kyradat" && make 2>&1 | tail -3

# Find existing KYRA.DAT
KDAT_DIR="$LIN/devtools/create_kyradat"
ls "$KDAT_DIR"/*.DAT "$KDAT_DIR"/KYRA.DAT 2>&1 | head

# Run create_kyradat
echo ""
echo "=== regen KYRA.DAT ==="
cd "$KDAT_DIR" && ./create_kyradat 2>&1 | tail -10

# Copy KYRA.DAT to deploy
if [ -f "$KDAT_DIR/out/KYRA.DAT" ]; then
    cp "$KDAT_DIR/out/KYRA.DAT" /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT
elif [ -f "$KDAT_DIR/KYRA.DAT" ]; then
    cp "$KDAT_DIR/KYRA.DAT" /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT
else
    echo "WARN: KYRA.DAT not found in standard locations"
    find "$KDAT_DIR" -name "KYRA.DAT" 2>/dev/null | head
fi
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT

# Build Win scummvm
echo ""
echo "=== build Win64 scummvm ==="
cd "$WIN" && make -j8 2>&1 | tail -3
cp "$WIN/scummvm.exe" /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe

# Build Linux scummvm
echo ""
echo "=== build Linux scummvm ==="
cd "$LIN" && make -j8 2>&1 | tail -3
cp "$LIN/scummvm" /tmp/eob_test/scummvm
sha256sum /tmp/eob_test/scummvm

echo ""
echo "=== iter23 deploy done ==="
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat
