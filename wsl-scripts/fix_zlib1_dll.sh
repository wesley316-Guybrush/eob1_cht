#!/bin/bash
# iter29: Add missing zlib1.dll to both Windows dist folders + repack ZIPs.
# scummvm.exe imports zlib1.dll dynamically; was missing from dist causing
# "找不到 zlib1.dll" error on machines without it pre-installed.
set -e

DIST=/mnt/d/03_game_tmp/eob1_cht/dist
ZLIB=/tmp/openxcom-src/build-win64-release/bin/zlib1.dll
WIN_BUILD=/mnt/d/03_game_tmp/eob1_cht/win64-build

# Verify zlib1.dll exists and is Win64 PE
if [ ! -f "$ZLIB" ]; then
    echo "FATAL: $ZLIB not found"; exit 1
fi
file "$ZLIB" | head -1
echo "size: $(stat -c '%s bytes' $ZLIB)"

# Deploy to win64-build (master copy)
cp "$ZLIB" "$WIN_BUILD/zlib1.dll"
echo "deployed to $WIN_BUILD/"

# Deploy to both dist folders
for VER in 15x15 16x16; do
    cp "$ZLIB" "$DIST/EOB1-CHT-$VER/zlib1.dll"
    echo "deployed to $DIST/EOB1-CHT-$VER/"
done

# Verify
echo ""
echo "=== Verification ==="
for VER in 15x15 16x16; do
    ls -la "$DIST/EOB1-CHT-$VER/"*.dll "$DIST/EOB1-CHT-$VER/"*.exe 2>&1 | head
    echo ""
done

# Re-pack ZIPs
echo "=== Re-pack ZIPs ==="
which zip || apt-get install -y zip
cd "$DIST"
for VER in 15x15 16x16; do
    OUT="EOB1-CHT-$VER-Win64.zip"
    rm -f "$OUT"
    cd "EOB1-CHT-$VER"
    zip -r9 "$DIST/$OUT" . -x "*.bak" "*.backup" 2>&1 | tail -5
    cd "$DIST"
done

echo ""
echo "=== Final ZIPs ==="
ls -la "$DIST"/*.zip
sha256sum "$DIST"/*.zip
