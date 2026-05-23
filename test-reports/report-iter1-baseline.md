# EOB1 CHT 測試報告 iter1 baseline

**Date**: 2026-05-23
**Tested binary**: `/root/scummvm_work/scummvm/scummvm` (Linux native, surfacesdl via Xvfb :99)
**KYRA.DAT**: `/root/eob1cht/KYRA.DAT` (2,034,422 bytes, 2026-05-23 02:05)
**ceob.pat**: `/root/eob1cht/ceob.pat` (357,528 bytes, 2026-05-23 01:51)
**Screenshots**: `screenshots/iter1-*.png` (51 frames)

## Helper script bug uncovered (for next iteration)

`eob1-headless.sh start` 用 `--auto-detect` 會開 ScummVM launcher GUI，那個視窗在 Xvfb 下立刻撞 `SDL_BlitSurface failed: SDL_UpperBlit: passed a NULL surface!` 致命錯誤而 exit；且 launcher fallback 視窗沒有 WM_CLASS，helper 的 `xdotool search --class scummvm` 找不到。

**Workaround**: 改用顯式 game ID 啟動：
```bash
nohup setsid env DISPLAY=:99 SDL_VIDEODRIVER=x11 \
  /root/scummvm_work/scummvm/scummvm --extrapath=/root/eob1cht --path=/root/eob1cht \
  --gfx-mode=surfacesdl kyra:eob \
  </dev/null >/tmp/eob1-tester/scummvm.log 2>&1 & disown
```

建議把 `start_scummvm` 改成傳 `kyra:eob` 給 argv，省掉 launcher。

## 通過 (P0 smoke tests)

- Main menu 中文 ✅ (`iter1-16-after-esc.png`) — 載入進行中遊戲 / 開始新隊伍
- CharGen empty screen 中文 ✅ (`iter1-17-chargen-empty.png`)
- Race menu 中文 ✅ (`iter1-18-race-menu.png`) — 人類/精靈/半精靈/矮人 男女
- Class menu 中文 ✅ (`iter1-19-class-menu.png`, `iter1-37-char4-class.png`) — 戰士/遊俠/聖騎/法師/牧師/盜賊 + 多職業 戰/牧, 戰/盜, 戰/法
- Alignment menu 中文 ✅ (`iter1-21-alignment-menu.png`) — 9 個陣營全中文
- CAMP menu 中文 ✅ (`iter1-03-camp-menu.png`)
- 遊戲選項 submenu 中文 ✅ (`iter1-06-game-options3.png`)
- Quit confirm dialog 中文 ✅ (`iter1-09-quit-confirm.png`)
- Name 欄位 ASCII 輸入正常 ✅ (`iter1-26-name-typed.png`)
- 隊伍完成 4 名角色，可按 P 進遊戲 ✅ (`iter1-40-party-done.png`, `iter1-41-game-start.png`)

## 問題 (12 個)

### BUG-001 [UX major] CharGen 標題與第一個選項上下重疊
- 場景: 種族/職業/陣營三個 menu
- 觀察: 「選擇XX：」標題與下方第一個選項 (人類男 / 戰士 / 守序善良) 字距太近，全形冒號的點壓到第一個字頂端
- Refs: `iter1-18-race-menu.png`, `iter1-19-class-menu.png`, `iter1-21-alignment-menu.png`
- 假設原因: 中文 12px 字身但 y-spacing 沿用英文版 8px 設定

### BUG-002 [UX **BLOCKER**] Stats 六屬性中文標籤垂直堆疊重疊無法閱讀
- 場景: Roll stats 畫面
- 觀察: 左側六屬性 (力/智/慧/敏/體/魅) 全部疊在同一個垂直 column 同一個 X 位置 → 一團糊住的字。對應數字 (e.g. 9/6/10/15) 也沒清楚對應。玩家無法判讀任何屬性數值，CharGen 失去意義。
- Refs: `iter1-22-stats-rolling.png`, `iter1-24-face-picked.png`, `iter1-31-char2-stats.png`, `iter1-35-char3-name-prompt.png`, `iter1-39-char4-stats.png`
- 假設原因: 原版英文 STR/INT/WIS/DEX/CON/CHA 每行 3 字母，render code 寫死 X advance；中文化把每行縮成 1 漢字後位置 collapsing。可能 `gui_eob.cpp` 的 statsGroup1/2 layout 用 `printStringIntern_statsPage`，stride 沒換算

### BUG-003 [UX major] CharGen 動作按鈕未中文化
- 場景: CharGen 各步驟底部
- 觀察: `REROLL` `MODIFY` `FACES` `KEEP` (`iter1-24`)、`BACK` (`iter1-19`, `iter1-21`)、`PLAY` 提示文 (`iter1-40` "選 PLAY 按鈕 或按 P 鍵") 都還是英文
- 假設原因: 可能是 bitmap sprite (在 PAK 內)，要重畫；或是漏翻的 string provider

### BUG-004 [UX major / font] 進入遊戲後肖像下方姓名欄字模殘缺
- 場景: 4 人隊伍進入遊戲
- 觀察: CharGen 名稱 `test` `test2` `test3` `test4` 在 in-game portrait 變成 `tact` `tact?` `tact?` `tact4`：`e`→`a`、digits `1/2/3` 變 `?`、但 `4` 正常
- Refs: `iter1-41-game-start.png`, `iter1-48`
- 假設原因: portrait name 用了另一個被中文化過程洗掉 ASCII glyph 的 font (可能是 FONT6.FNT 或 OldDOSFont 在 ZH_TWN 模式下被取代)

### BUG-005 [UX minor] 「踢出角色」的「色」字 glyph 破損
- Refs: `iter1-06-game-options3.png`
- 假設原因: 字模 bug 或 BIG5 解析 off-by-one

### BUG-006 [UX cosmetic] 「沒有可以謄寫的卷軸。」第一個「沒」字 glyph 看似誤植
- Refs: `iter1-04-game-options.png`
- 假設原因: BIG5 查表錯，或 source string 用錯字

### BUG-007 [UX cosmetic] 多職業縮寫「戰/牧」「戰/盜」「戰/法」與一般職業字寬不一致
- 觀察: 全形+半形斜線+全形 vs 兩全形，視覺鬆散
- Refs: `iter1-29-race-scrolled.png`
- 建議: 統一格式 (戰牧/戰盜/戰法 全形, 或全用 `／` 全形斜線)

### BUG-008 [UX minor] BACK 按鈕下方漏出上一頁底層文字
- Refs: `iter1-19-class-menu.png`
- 觀察: Alignment menu redraw 沒清除前一頁底部，看得到 race menu 的「矮人女」字尾

### BUG-009 [UX minor] CAMP 標題「營：」黏到第一個選項「休息隊伍」
- Refs: `iter1-03-camp-menu.png`
- 同 BUG-001 — Y-spacing 問題

### BUG-010 [UX cosmetic] 陣營選項間距不一致
- 觀察: 守序善良無空白，但中立/混亂善良 等有「2字-空白-2字」格式
- Refs: `iter1-21-alignment-menu.png`, `iter1-34-char3-mid.png`
- 9 個選項只有第 1 個排版不同

### BUG-011 [UX minor] Race/gender/class 標頭顯示行高過密、multi-class 顯示可能缺失
- char3「人類男」(行 1) 「遊俠」(行 2) 兩行緊鄰
- char2 (半精靈女戰士/牧師) stats 畫面只顯示「半精靈女」，看不到「戰士/牧師」第 2 行 — 可能被裁
- Refs: `iter1-31-char2-stats.png`, `iter1-35-char3-name-prompt.png`

### BUG-012 [UX minor] 第一個 character 的 race+class 與 stat 標籤縱向擠壓
- Refs: `iter1-24-face-picked.png`
- 「人類男」+「戰士」+ stat 標籤之間 padding 不足

## 嚴重度統計

- **blocker**: 1 (BUG-002)
- **major**: 3 (BUG-001, BUG-003, BUG-004)
- **minor**: 5 (BUG-005, BUG-008, BUG-009, BUG-011, BUG-012)
- **cosmetic**: 3 (BUG-006, BUG-007, BUG-010)

## [UX] 標籤清單 — 全部 12 個都打 [UX]，ux-designer 全收

BUG-001 / **BUG-002 (BLOCKER, priority 1)** / BUG-003 / BUG-004 / BUG-005 / BUG-006 / BUG-007 / BUG-008 / BUG-009 / BUG-010 / BUG-011 / BUG-012

## ScummVM 穩定性

ScummVM 跑了兩個 session — 第一次 quit-game flow 退到 launcher 結束，第二次完整跑 CharGen 4 人 + 進遊戲 + 開 CAMP menu。在遊戲中按 Escape 兩次 (退出 CAMP 子選單 + 退出 CAMP 主選單) 後 ScummVM 直接 exit — 可能是 surfacesdl 在 Xvfb 下 Escape handling bug，或 EOB engine 真會在第 2 個 Esc quit。整體無 crash log/segfault。Restart 次數 = 1。

## Final state

- ScummVM 已透過 `eob1-headless.sh stop` 停止 (pgrep 確認無 scummvm/Xvfb 進程)
- 51 張 PNG 截圖保留在 `screenshots/iter1-*.png`
