#!/bin/bash
# iter27: build TWO Win64 binaries
#   scummvm-15.exe (engine load 15) - current iter26
#   scummvm-16.exe (engine load 16) - native Unifont 16×16
set -e
SRC=/mnt/d/03_game_tmp/eob1_cht/scummvm-source
WIN=/root/scummvm_work/scummvm-win64-build
F=engines/kyra/graphics/screen_eob.cpp

# Stash original (15-tall) version
cp "$WIN/$F" "$WIN/${F}.iter26"

# === Build 15-tall (current iter26 source) ===
echo "=== build scummvm-15.exe ==="
cd "$WIN" && make -j8 2>&1 | tail -3
cp "$WIN/scummvm.exe" /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm-15.exe
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm-15.exe

# === Patch to 16-tall and rebuild ===
echo ""
echo "=== patch engine to load 16 ==="
sed -i 's|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 15 : 14);|loadPrefixedRaw(f, (_vm->game() == GI_EOB1) ? 16 : 14); // iter27 16x16 variant|' "$WIN/$F"
grep -n "loadPrefixedRaw(f," "$WIN/$F" | head -1

echo ""
echo "=== build scummvm-16.exe ==="
cd "$WIN" && make -j8 engines/kyra/graphics/screen_eob.o 2>&1 | tail -3
make -j8 2>&1 | tail -3
cp "$WIN/scummvm.exe" /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm-16.exe
sha256sum /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm-16.exe

# === Restore source to 15-tall (so future builds aren't broken) ===
cp "$WIN/${F}.iter26" "$WIN/$F"
rm "$WIN/${F}.iter26"
grep -n "loadPrefixedRaw(f," "$WIN/$F" | head -1

echo ""
echo "=== Both binaries ready ==="
ls -la /mnt/d/03_game_tmp/eob1_cht/win64-build/scummvm-1{5,6}.exe
