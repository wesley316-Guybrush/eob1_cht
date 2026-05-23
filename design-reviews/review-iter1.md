# Design Review iter1 — 2026-05-23

Reviewing iter1 baseline test report. Focus is ruthlessly narrow: the BLOCKER (BUG-002) plus the two clear-cut majors (BUG-001/009 spacing, BUG-004 portrait names). The other 9 bugs are deferred — fixing them now would couple risk to multiple unrelated changes and dilute the iteration signal.

## Source bugs reviewed (this round)

- **BUG-002 (BLOCKER)** — Stats labels 力/智/慧/敏/體/魅 stacked into one overlapping column at x=163 (`iter1-23-stats-full.png`, `iter1-24-face-picked.png`)
- **BUG-001 + BUG-009 (major + minor, same root cause)** — Title `選擇XX：` / `營：` overlapping first menu item (`iter1-19`, `iter1-21`, `iter1-03`)
- **BUG-004 (major)** — In-game portrait names `test1..test4` rendered as `tact?` `tact?` `tact?` `tact4` (`iter1-41`, `iter1-48`)

The other 9 bugs (BUG-003 English buttons, BUG-005 「色」 glyph, BUG-006 「沒」 glyph, BUG-007 multi-class slash, BUG-008 BACK button leak, BUG-010 alignment spacing, BUG-011 multi-line race/class label, BUG-012 race+stat squeeze) are **deferred to iter 2**. Several may auto-resolve once the layout fixes below are in (BUG-011 and BUG-012 are likely downstream of BUG-002).

---

## Root cause analysis

### Issue 1: EOB1 ZH_TWN falls into the English `printStats` branch

File: `scummvm-source/engines/kyra/engine/chargen.cpp`, function `CharacterGenerator::printStats` (line 1275).

The function has three branches:

```cpp
if (platform == kPlatformSegaCD) {            // line 1293
    ... Sega-specific layout
} else if (game() == GI_EOB2 && lang == ZH_TWN) {   // line 1300 ← CHT branch
    // Two-column stat layout: x=165/240, y=64/80/96 (16-px stride)
    // Each label is one Chinese char; uses FID_8_FNT for numbers.
} else {                                       // line 1332 ← English (and EOB1 ZH_TWN!)
    // Single-column labels at x=163, y=(i+8)<<3 (8-px stride, 6 rows: 64..104)
    // Numbers come from str1 ("%s\r%d\r%d\r%d\r%d\r%d") at x=192
}
```

EOB1 ZH_TWN currently hits the third branch. With a 12-px-tall Chinese font and an 8-px Y stride, six labels render into ~56 px of space → consecutive labels overlap by 4 px each → the screenshot disaster.

The EOB2 ZH layout (165/240 + 16-px stride) was carefully designed for 12-px Chinese chars. EOB1 should reuse it verbatim — there is no game-specific reason for these coordinates to differ. The right fix is to relax the condition.

There are companion call sites in the same function that gate other ZH-specific behavior on `game() == GI_EOB2`:

- Line 1285: face shape X offset (289 vs 224)

That coordinate too should apply to EOB1 ZH (the face goes into the same right-column slot the EOB2 layout assumes).

Affected screens: every stats screen during CharGen (rolling, modify, faces, keep, view).

### Issue 2: Menu title Y-coordinate too close to first item for 12-px font

File: `scummvm-source/engines/kyra/engine/chargen.cpp`

- `raceSexMenu` line 800: title y = `(EOB2 && ZH) ? 65 : 67`
- `classMenu` line 842/845: title y = 65 (ZH branch is EOB2-only) / 67 (else, includes EOB1 ZH)
- `alignmentMenu` (similar pattern — same EOB2-only ZH branch)

The first menu item is rendered at `_menuPoint.y = _screen->_curDim->sy + dm->sy`. With `setScreenDim(2)` → `_curDim->sy = 0x40 = 64` and `_screenDimTableZH` entry 20/21/22 having `sy = 0x10 = 16`, the first item lands at **y = 80**.

So we have title at y=67 (English, used by EOB1 ZH) and first item at y=80. Distance = 13 px. With a 12-px-tall Chinese title, only 1 px of vertical breathing room → the full-width colon `：` of `選擇XX：` collides with the top stroke of the first item (`人`, `戰`, `守`).

The CAMP menu (BUG-009) is the in-game analog using the same simpleMenu + same Chinese font → same overlap (`營：` glued to `休息隊伍`).

Same fix idea as Issue 1: relax the EOB2-only ZH condition. The y=65 title position used by EOB2 ZH (2 px higher than English) is the safer baseline; EOB1 ZH should adopt it too. We won't try to push the first-item start lower (that would require changing the screen dim table, which has wider ripple effects).

### Issue 3: Portrait name area uses FID_CHINESE_FNT (tall PCBIOS font) instead of FID_6_FNT

File: `scummvm-source/engines/kyra/engine/eobcommon.cpp`, line 613-617.

```cpp
} else if (_flags.lang == Common::ZH_TWN) {
    _screen->loadFont(Screen::FID_CHINESE_FNT, "FONT8.FNT");
    _titleFont = _conFont = _invFont1 = _invFont2 = _invFont4 = Screen::FID_CHINESE_FNT;
    _invFont5 = Screen::FID_8_FNT;
}
```

`_invFont1` is the **portrait name font** (set at `gui_eob.cpp:118` before drawing each portrait's `c->name`). Default value is FID_6_FNT (line 202).

`FID_CHINESE_FNT` is intercepted in `Screen_EoB::loadFont` (screen_eob.cpp:1758-1764) — it builds a fresh `OldDOSFont` via `loadPCBIOSTall()`, which is **15 px tall** (8x8 PCBIOS rom font, each row doubled to give 15-row output). Then wraps in `ChineseTwoByteFontEoB`.

The portrait name slot is sized for ~8 px (`FID_6_FNT` is 6 high). The 15-tall glyphs get visually clipped at the bottom by the face shape redraw that overwrites the lower half. What survives is the TOP HALF of each glyph:

- `e` top-half → looks like `a`
- `s` top-half → looks like `c`
- `1`, `2`, `3` top-halves → cropped to look like `?`
- `4` top stroke survives intact → reads as `4`

That matches the report exactly (`test1` → `tact?`, `test4` → `tact4`).

`FID_6_FNT` was already loaded at line 595 via `loadFont(FID_6_FNT, "FONT6.FNT")`. That path **also** wraps the font in `ChineseTwoByteFontEoB` at line 1779-1780 (`if (_big5) fnt = new ChineseTwoByteFontEoB(_big5, fnt);`). So FID_6_FNT in ZH_TWN mode already supports BIG5 — its ASCII side is the original 6-tall FONT6.FNT (correct for portrait names), its Chinese side is the 12-tall Big5 (only used if a Chinese char appears in the name, which is currently impossible since name input is ASCII-only).

Fix: don't reassign `_invFont1` to FID_CHINESE_FNT. Leave `_invFont1` and `_invFont2` at the FID_6_FNT default. Keep the reassignment only for `_titleFont`, `_conFont`, `_invFont4` (those slots draw Chinese UI text where 12-px height is required).

Risk note: `_invFont2` is used for weapon-slot text and HP digits (`gui_eob.cpp:137`). Reverting `_invFont2` is slightly more invasive — we should keep it as FID_CHINESE_FNT for now since the report shows no bug there, and only revert `_invFont1`.

Affected screens: every in-game portrait (always visible), CAMP, REST.

---

## Proposed fixes

### Fix A: Extend `printStats` ZH-CHT layout branch to EOB1

File: `scummvm-source/engines/kyra/engine/chargen.cpp`
Effort: small (2 line condition change + 1 line condition change)
Risk: low — copies known-good EOB2 ZH layout to EOB1 ZH, no new coords introduced. EOB2 ZH path remains byte-identical. EOB1 EN/DE/IT/ES paths remain byte-identical.

Sample patch:

```diff
@@ chargen.cpp:1284-1286
 		if (mode != 4)
-			_screen->drawShape(2, c->faceShape, (_vm->game() == GI_EOB2 && _vm->gameFlags().lang == Common::Language::ZH_TWN) ? 289 : 224, 2, 0);
+			_screen->drawShape(2, c->faceShape, (_vm->gameFlags().lang == Common::Language::ZH_TWN) ? 289 : 224, 2, 0);
 	}
```

```diff
@@ chargen.cpp:1300
 	} else if (_vm->gameFlags().platform == Common::kPlatformSegaCD) {
 		...
-	} else if (_vm->game() == GI_EOB2 && _vm->gameFlags().lang == Common::Language::ZH_TWN) {
+	} else if (_vm->gameFlags().lang == Common::Language::ZH_TWN) {
 		_screen->printShadedText(c->name, 245, 34, _vm->guiSettings()->colors.guiColorBlue, 0, _vm->guiSettings()->colors.guiColorBlack);
 		_screen->printShadedText(_chargenRaceSexStrings[c->raceSex], 165, 34, ...);
 		...
```

**Verification expectation**: after fix, stats screen shows two columns of one-char labels (力/智/慧 in left col at x=165, 敏/體/魅 in right col at x=240), each on its own 16-px-spaced row, with numbers cleanly to the right of each label.

**What could break**:
- Other languages (EN/DE/IT/ES) untouched — they still hit the `else` branch.
- EOB2 ZH untouched — its condition is now a strict subset of the relaxed one but the code body is identical.
- Only EOB1 ZH behavior changes. Specifically: the face shape moves from x=224 to x=289, AC/HP/LVL labels move from a single combined string to three separate `防:` `命:` `級:` strings, and numbers use FID_8_FNT instead of the wrapped Chinese font for digit rendering. All of these match the EOB2 ZH visual already proven in the field.

### Fix B: Extend menu title Y-coord ZH branches to EOB1

File: `scummvm-source/engines/kyra/engine/chargen.cpp`
Effort: trivial (drop the `game() == GI_EOB2 &&` part in three menu functions)
Risk: low — moves title up by 2 px for EOB1 ZH (67 → 65), matching the already-shipped EOB2 ZH value.

Note: BUG-009 (CAMP menu `營：` overlap) is **NOT** fixed by this patch — CAMP uses a different menu path (`gui_eob.cpp` runtime menus, not chargen). The same root cause (12-px font over an 8-stride menu) applies but the fix lives elsewhere. I'm rolling BUG-009 forward to iter 2 unless the developer wants to grep `printShadedText.*營` while in this file (it's a 1-minute find but I haven't traced the call site for this iteration; better not to balloon scope).

Sample patch (chargen.cpp, classMenu around line 841-847):

```diff
-	} else if (_vm->game() == GI_EOB2 && _vm->gameFlags().lang == Common::Language::ZH_TWN) {
+	} else if (_vm->gameFlags().lang == Common::Language::ZH_TWN) {
 		_screen->printShadedText(_chargenStrings2[9], 145, 65,
 			_vm->guiSettings()->colors.guiColorLightBlue, 0, _vm->guiSettings()->colors.guiColorBlack);
 	} else {
 		_screen->printShadedText(_chargenStrings2[9], 147, 67,
 			_vm->guiSettings()->colors.guiColorLightBlue, 0, _vm->guiSettings()->colors.guiColorBlack);
 	}
```

Apply the analogous change to `raceSexMenu` (line ~800, condition `_vm->game() == GI_EOB2 && _vm->gameFlags().lang == Common::Language::ZH_TWN`) and to `alignmentMenu` (same pattern — developer please grep for the EOB2-ZH condition in `chargen.cpp` to find all three menus).

**Verification expectation**: title `選擇種族：` / `選擇職業：` / `選擇陣營：` sits 2 px higher; the full-width colon `：` no longer collides with the top stroke of `人類男` / `戰士` / `守序善良`.

**What could break**: title baseline moves up 2 px — already in production for EOB2 ZH, so visual is known-acceptable. If the title was rendered into a clipped box that's now too low at the top, we'd see clipping — but the menu area has plenty of headroom (`_curDim->sy = 64`, title y=65 means it sits ~1 px below the top of that region).

### Fix C: Revert `_invFont1` for ZH_TWN to FID_6_FNT

File: `scummvm-source/engines/kyra/engine/eobcommon.cpp`
Effort: trivial (one assignment line)
Risk: low — restores the default font for portrait names; FID_6_FNT is already loaded and already wrapped in BIG5 support.

Sample patch (line 615):

```diff
 	} else if (_flags.lang == Common::ZH_TWN) {
 		_screen->loadFont(Screen::FID_CHINESE_FNT, "FONT8.FNT");
-		_titleFont = _conFont = _invFont1 = _invFont2 = _invFont4 = Screen::FID_CHINESE_FNT;
+		_titleFont = _conFont = _invFont2 = _invFont4 = Screen::FID_CHINESE_FNT;
+		// _invFont1 stays at FID_6_FNT (default). It draws portrait names (gui_eob.cpp:132)
+		// into a slot sized for 6-px-tall ASCII. FID_CHINESE_FNT uses loadPCBIOSTall (15-tall)
+		// which clips and produces the "tact?" rendering reported as BUG-004.
 		_invFont5 = Screen::FID_8_FNT;
 	}
```

**Verification expectation**: portrait names show full ASCII (`test1`, `test2`, `test3`, `test4`) cleanly, no clipping. Other ZH UI text (CAMP menu items, dialogue, options) is unaffected — `_titleFont`/`_conFont`/`_invFont4` still use FID_CHINESE_FNT.

**What could break**:
- If anywhere `_invFont1` is set and then used to draw Chinese, those Chinese chars now render at 6-tall via the BIG5 wrap. The wrap returns `MAX(big5_height, singleByte_height)` for `getHeight()` so total height is 12 — but per-char Chinese glyphs from `_big5->drawBig5Char` are 12 tall regardless of singleByte font height. So Chinese chars would draw at 12-tall into a 6-tall slot → would clip in the SAME way the ASCII does now, BUT we've inspected: portrait names are ASCII-only (name input doesn't accept Chinese). So this is safe in practice.
- Inventory-screen text (`gui_eob.cpp:191-193` uses `_invFont1` indirectly via the parent fall-through path) — needs visual check after rebuild. If a regression appears, narrow the fix further by adding a per-call-site `setFont` instead of changing the global default.

---

## Recommended order

1. **Fix C** (trivial, isolated to one line, fixes BUG-004 immediately) — apply first, rebuild, eyeball portraits.
2. **Fix A** (BLOCKER, but slightly more code touched) — apply second.
3. **Fix B** (cosmetic gain on titles) — apply third.

All three are independent — order is preference, not dependency.

## Open questions (need developer input)

- **For Fix A**: in the EOB2 ZH branch at line 1300, the face shape draw is conditional (`if (mode != 4)`). Same gating already applies after Fix A — no change needed. But confirm that EOB1's `mode` values match EOB2's (the `printStats(idx, mode)` call sites in chargen.cpp lines 662, 718, 763, etc. pass modes 0/1/2/3/4 — same as EOB2). I'm confident but flagging for the developer to spot-check.
- **For Fix C**: after rebuild, please check the inventory screen (CAMP → 「裝備」 if it exists, or just open a character sheet) to confirm `_invFont1`-rendered text other than portrait names still looks acceptable. The bookFont / classFont / spell list use FID_CHINESE_FNT via `_titleFont`/`_invFont4` and are unaffected by Fix C.
- **For BUG-009 (CAMP `營：` overlap)**: I deferred this because the fix lives in the in-game menu code, not chargen. Iter 2 should target it specifically — grep for `_screen->printShadedText` calls near where CAMP options are listed (probably `gui_eob.cpp` somewhere around `runCamp` or `gui_drawCampMenu`).

## Approval criteria (apply Fix A+B+C, re-test, screenshot review)

- [ ] Stats screen: six attribute labels visible as 2 columns × 3 rows, no overlap (`力`/`敏` row 1, `智`/`體` row 2, `慧`/`魅` row 3)
- [ ] Stats screen: numeric values cleanly to the right of each label
- [ ] Race/class/alignment menus: title `選擇XX：` no longer overlaps first item
- [ ] In-game portraits: names show as `test1`/`test2`/`test3`/`test4` (or whatever was entered) with no clipping
- [ ] No regression in: main menu, CharGen empty screen, name input field, race/class/alignment menu BODY text, CAMP submenu options, quit dialog (all should look identical to iter1)
