#!/bin/bash
SRC=/mnt/d/03_game_tmp/eob1_cht/scummvm-source
LIN=/root/scummvm_work/scummvm
WIN=/root/scummvm_work/scummvm-win64-build
for f in engines/kyra/gui/saveload_eob.cpp engines/kyra/gui/gui_eob.cpp engines/kyra/engine/magic_eob.cpp; do
    cp "$SRC/$f" "$LIN/$f"
    cp "$SRC/$f" "$WIN/$f"
    echo "  synced $f"
done
echo "Done"
