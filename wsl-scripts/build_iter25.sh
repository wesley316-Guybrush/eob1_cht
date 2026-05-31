#!/bin/bash
# iter25: 中止施法 restored at bottom + listSize 3→2 + 16x15 variant available
set -e
SRC=/mnt/d/03_game_tmp/eob1_cht/scummvm-source
LIN=/root/scummvm_work/scummvm
WIN=/root/scummvm_work/scummvm-win64-build

for D in "$LIN" "$WIN"; do
    cp "$SRC/engines/kyra/resource/staticres_eob.cpp" "$D/engines/kyra/resource/staticres_eob.cpp"
done
cp "$SRC/devtools/create_kyradat/resources/eob1_dos_chinese.h" "$LIN/devtools/create_kyradat/resources/eob1_dos_chinese.h"
echo "synced"

echo ""
echo "=== rebuild create_kyradat ==="
cd "$LIN" && make -j8 devtools/create_kyradat/create_kyradat 2>&1 | tail -3

echo ""
echo "=== regen KYRA.DAT ==="
cd "$LIN/devtools/create_kyradat" && ./create_kyradat /tmp/kyra_iter25 2>&1 | tail -3
cp /tmp/kyra_iter25 /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT

echo ""
echo "=== build Win scummvm ==="
cd "$WIN" && make -j8 2>&1 | tail -3
cp "$WIN/scummvm.exe" /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe

echo ""
echo "=== iter25 deploy done ==="
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm.exe \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat \
          /mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_16x15.pat 2>&1
