#!/bin/bash
# Build 2 separate dist folders for 15x15 and 16x16 font variants.
# Each has its own scummvm.exe + ceob.pat + full game files + 啟動.bat.
set -e

BASE=/mnt/d/03_game_tmp/eob1_cht
DIST=$BASE/dist
SRC_GAME=$BASE/win64-build/game
SRC_WIN=$BASE/win64-build

# Cleanup old dual-folder builds
rm -rf "$DIST/EOB1-CHT-15x15" "$DIST/EOB1-CHT-16x16"
mkdir -p "$DIST/EOB1-CHT-15x15/game" "$DIST/EOB1-CHT-16x16/game"

# === Common game files (both versions) ===
# All game data files but EXCLUDE the *.bak / staging pat files
for f in CGA.OVL EGA.OVL EOB.EXE EOBDATA1.PAK EOBDATA2.PAK EOBDATA3.PAK \
         EOBDATA4.PAK EOBDATA5.PAK EOBDATA6.PAK EYE.PAK FONT6.FNT FONT8.FNT \
         INTRO.EXE LEVELS.TMP MCGA.OVL START.EXE TEXT.DAT TGA.OVL \
         KYRA.DAT README.md .gitkeep; do
    [ -f "$SRC_GAME/$f" ] && cp "$SRC_GAME/$f" "$DIST/EOB1-CHT-15x15/game/$f"
    [ -f "$SRC_GAME/$f" ] && cp "$SRC_GAME/$f" "$DIST/EOB1-CHT-16x16/game/$f"
done

# === 15×15 version ===
echo "=== 15x15 version ==="
cp "$SRC_WIN/scummvm-15.exe" "$DIST/EOB1-CHT-15x15/scummvm.exe"
cp "$SRC_WIN/SDL2.dll" "$DIST/EOB1-CHT-15x15/"
# ceob.pat = current active (iter26 15×15)
cp "$SRC_WIN/game/ceob.pat" "$DIST/EOB1-CHT-15x15/game/ceob.pat"
echo "15×15 ceob.pat: $(stat -c '%s bytes' "$DIST/EOB1-CHT-15x15/game/ceob.pat")"
ls "$DIST/EOB1-CHT-15x15/game/" | wc -l

# === 16×16 version ===
echo "=== 16x16 version ==="
cp "$SRC_WIN/scummvm-16.exe" "$DIST/EOB1-CHT-16x16/scummvm.exe"
cp "$SRC_WIN/SDL2.dll" "$DIST/EOB1-CHT-16x16/"
# ceob.pat = original Unifont 16×16
cp "$SRC_WIN/game/ceob_16tall.pat.bak" "$DIST/EOB1-CHT-16x16/game/ceob.pat"
echo "16×16 ceob.pat: $(stat -c '%s bytes' "$DIST/EOB1-CHT-16x16/game/ceob.pat")"
ls "$DIST/EOB1-CHT-16x16/game/" | wc -l

echo ""
echo "=== Sizes ==="
du -sh "$DIST/EOB1-CHT-15x15/" "$DIST/EOB1-CHT-16x16/"

echo ""
echo "=== Verify both binaries ==="
sha256sum "$DIST/EOB1-CHT-15x15/scummvm.exe" "$DIST/EOB1-CHT-16x16/scummvm.exe"
sha256sum "$DIST/EOB1-CHT-15x15/game/ceob.pat" "$DIST/EOB1-CHT-16x16/game/ceob.pat"
