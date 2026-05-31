#!/bin/bash
# iter26: 15×15 active font + spellbook background extended to cover 中止施法
set -e
SRC=/mnt/d/03_game_tmp/eob1_cht/scummvm-source
LIN=/root/scummvm_work/scummvm
WIN=/root/scummvm_work/scummvm-win64-build

for f in engines/kyra/graphics/screen_eob.cpp \
         engines/kyra/resource/staticres_eob.cpp \
         engines/kyra/engine/magic_eob.cpp \
         engines/kyra/gui/gui_eob.cpp; do
    cp "$SRC/$f" "$LIN/$f"
    cp "$SRC/$f" "$WIN/$f"
    echo "synced $f"
done

echo ""
echo "=== build Win scummvm ==="
cd "$WIN" && make -j8 2>&1 | tail -5
cp "$WIN/scummvm.exe" /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe

echo ""
echo "=== iter26 deploy summary ==="
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat
ls -la /mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob*.bak 2>&1 | head
