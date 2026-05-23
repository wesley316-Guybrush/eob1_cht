# Build applied — iter1 (2026-05-23 08:05)

Source review: `design-reviews/review-iter1.md`

## Fixes applied

### Fix A — Extend `printStats` ZH-CHT layout to EOB1
- **Status**: Applied as proposed.
- **File**: `scummvm-source/engines/kyra/engine/chargen.cpp`
- **Edits**:
  - Line 1285: dropped `game() == GI_EOB2 &&` from the face-shape X-offset ternary. EOB1 ZH now uses x=289 (was 224).
  - Line 1300: relaxed branch condition from `(GI_EOB2 && ZH_TWN)` to `(ZH_TWN)`. EOB1 ZH now hits the same two-column 16-px-stride stat layout as EOB2 ZH.
- **Verified no syntax errors**: condition still well-formed, brace structure unchanged. EOB2 ZH path is byte-identical (now reached via the relaxed condition with same body). Other-language paths unchanged.

### Fix B — Extend menu title Y=65 to EOB1 ZH (three menus)
- **Status**: Applied as proposed. Patched all three menu functions.
- **File**: `scummvm-source/engines/kyra/engine/chargen.cpp`
- **Edits**:
  - Line ~800 (`raceSexMenu`): dropped `game() == GI_EOB2 &&` from inline ternary. ZH title now at y=65.
  - Lines ~841 (`classMenu`): dropped `game() == GI_EOB2 &&` from `else if` branch. ZH title now at y=65 (x=145).
  - Lines ~919 (`alignmentMenu`): dropped `game() == GI_EOB2 &&` from multi-line ternary. ZH title now at y=65.
- Grep confirms zero remaining occurrences of the old `GI_EOB2 && _vm->gameFlags().lang == Common::Language::ZH_TWN` pattern in `chargen.cpp`.

### Fix C — Revert `_invFont1` for ZH_TWN to FID_6_FNT default
- **Status**: Applied as proposed.
- **File**: `scummvm-source/engines/kyra/engine/eobcommon.cpp` (line 613-619)
- **Edit**: removed `_invFont1 =` from the chained assignment of `Screen::FID_CHINESE_FNT`. `_invFont1` now stays at its default FID_6_FNT, so portrait names render via the 6-tall ASCII font (BIG5 wrap still in place for any Chinese chars, though name input is ASCII-only). Added 3-line explanatory comment.
- `_titleFont`, `_conFont`, `_invFont2`, `_invFont4` still assigned FID_CHINESE_FNT (Chinese UI text unaffected).

## Build status

| Target | Status | Binary | Size | SHA-256 |
|---|---|---|---|---|
| Linux (WSL, `/root/scummvm_work/scummvm/scummvm`) | OK | scummvm | 43,652,488 B | `26aa28bee4812800224f19ee4f1413e60f2158d9fbc27cf72fa364c13e60ac4a` |
| Windows (MinGW cross, stripped) | OK | scummvm.exe | 27,059,712 B | `aac91bc8f072b4768efd0e83248b1a11b8740134fb7613f5a2a5c35053e71947` |

Both builds completed cleanly — only `chargen.o` and `eobcommon.o` recompiled (incremental), then libkyra.a re-archived and final LINK succeeded. No warnings flagged in tail output.

Windows binary copied to `D:\03_game_tmp\eob1_cht\win64-build\scummvm.exe` (overwriting the pre-fix one).

## What changed for downstream (next tester run)

- **scummvm (Linux, tester's binary)**: rebuilt — pick up the new binary at `/root/scummvm_work/scummvm/scummvm`.
- **scummvm.exe (Windows, user's binary)**: rebuilt and dropped into `win64-build/`.
- **KYRA.DAT**: *unchanged* — no string/resource modifications this iter.
- **ceob.pat**: *unchanged*.

Re-test priority for iter2 baseline:
1. CharGen stats screen (BUG-002) — expect 2 columns × 4 rows of stat labels (力/敏 / 智/體 / 慧/魅 / plus 防/命/級 row), no overlap; numbers cleanly right of each label; face shape at x=289.
2. Race/Class/Alignment title rows (BUG-001) — expect `選擇XX：` 2 px higher, full-width colon no longer touching first menu item.
3. In-game portrait names (BUG-004) — expect `test1`/`test2`/`test3`/`test4` rendered cleanly with no top-half-only clipping.
4. **Spot-check for regressions**: CAMP submenu (still has BUG-009 `營：` overlap — known deferred), inventory screen (`_invFont1` revert side-effects, per review's open question), quit dialog, main menu, name input field.
5. CAMP menu `營：` overlap (BUG-009) — **NOT** fixed this iter; lives in `gui_eob.cpp`, deferred to iter2.

## Assumptions / notes

- Source structure unchanged since review was written — all proposed diffs applied verbatim with no need for equivalent rewrites.
- Did not touch `ceob.pat` or `KYRA.DAT` (per user constraint and per review — no resource edits needed).
- Did not run scummvm to verify visually (tester's job).
- The three menu functions in Fix B had two distinct syntactic patterns (inline ternary in raceSex/alignment, `else if` block in class) — both handled correctly with separate edits.

## Ready for re-test

Yes — game-tester should re-run iter1 P0/P1 scenarios (intro skip → CharGen race/class/alignment → stats screen → name entry → enter dungeon → check portraits) against the new binaries.
