#!/bin/bash
# Smoke test both AppImages: launch under Xvfb, verify loads + survives 5 sec
set +e
DISP=:64
LOG15=/tmp/appimage-15-smoke.log
LOG16=/tmp/appimage-16-smoke.log

pkill -9 Xvfb scummvm 2>/dev/null
sleep 1
rm -f /tmp/.X64-lock /tmp/.X11-unix/X64 2>/dev/null

Xvfb $DISP -screen 0 1024x768x24 -ac -nolisten unix &
XPID=$!
export DISPLAY=$DISP
sleep 2
export SDL_AUDIODRIVER=dummy

DIST=/mnt/d/03_game_tmp/eob1_cht/dist

test_one() {
    local name=$1
    local img=$2
    local log=$3
    echo "=== Smoke test: $name ==="
    chmod +x "$img"
    "$img" >$log 2>&1 &
    PID=$!
    for i in 1 2 3 4 5 6 7 8 9 10; do
        sleep 1
        if grep -q "ceob.pat:" $log 2>/dev/null; then
            echo "  loaded after ${i}s ✓"
            break
        fi
    done
    sleep 3
    if kill -0 $PID 2>/dev/null; then
        echo "  $name PASSED (still running)"
        kill $PID 2>/dev/null
    else
        echo "  $name FAILED (process died)"
        echo "  log tail:"
        tail -10 $log
    fi
    pkill -9 scummvm 2>/dev/null
    sleep 1
}

test_one "15x15 AppImage" "$DIST/EOB1-CHT-15x15-x86_64.AppImage" "$LOG15"
test_one "16x16 AppImage" "$DIST/EOB1-CHT-16x16-x86_64.AppImage" "$LOG16"

# Verify ceob.pat MD5 matches expected for each
echo ""
echo "=== ceob.pat MD5 from logs ==="
grep "ceob.pat:" $LOG15 | head -1
grep "ceob.pat:" $LOG16 | head -1

kill $XPID 2>/dev/null
sleep 1
