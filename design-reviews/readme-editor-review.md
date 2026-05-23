# README.md 編輯審查報告

Date: 2026-05-23
Reviewer: editor-in-chief subagent
Scope: `D:\03_game_tmp\eob1_cht\README.md` 全文 + 引用資源驗證

## Summary

- **整體品質: A-**
- **Critical issues: 1 個** (數字不一致 — 9 vs 11)
- **Minor issues: 6 個** (typo / 用詞 / TOC 缺失 / 致謝小漏 / level_messages.md 內部漢化未跟進)
- **譯名統一: PASS** (全文 3 處「深水城」，0 處「水深市」殘留)
- **截圖引用: PASS** (5/5 全部存在)
- **翻譯索引連結: PASS** (4/4 全部存在，數字同步)
- **建議: ship/push 前先修 Critical issue + 至少 3 個 Minor，預估 10 min**

---

## 截圖驗證 (Step 2)

README 引用的 5 張 PNG，全部實際存在於 `test-reports/screenshots/`:

| README 引用 | 行號 | 檔案存在 |
|---|---|---|
| `iter6-MEGA-A-01-race.png` | L52 | YES |
| `iter6-MEGA-A-05-statsbtn.png` | L55 | YES |
| `iter6-MEGA-A-06-name.png` | L58 | YES |
| `iter6-MEGA-fixI-11-pageflip-corner.png` | L63 | YES |
| `iter6-MEGA-camp-final.png` | L66 | YES |

旁註: `test-reports/screenshots/` 實有 50+ 張 (iter1~iter6 全程記錄)，README L71 描述「完整 50+ 截圖」與實際吻合。

---

## 翻譯索引連結驗證 (Step 3)

| README 連結 | 目標檔案 | 存在 | 數字一致性 |
|---|---|---|---|
| `translations/items.md` | exists | YES | README 寫「95 物品」/「(95 項)」, items.md heading 寫「95 項」 ✓ |
| `translations/dialogue.md` | exists | YES | README 寫「51 NPC 對話/文件/謎語」, dialogue.md heading 寫「51 項」 ✓ |
| `translations/level_messages.md` | exists | YES | README 寫「168 strings 抽出」, level_messages.md 章節 LEVEL1~12 全部存在 ✓ |
| `translations/README.md` | exists | YES | (索引總覽) |
| `docs/future-work.md` | (未驗證, README L238 引用) | — | — |
| `win64-build/game/README.md` | exists | YES | (game/ 安裝指引) |
| `docs/lessons-learned.md` | (README L281 引用) | — | — |

---

## 內容問題

### Critical issues

#### C1. 數字不一致：「9 個 Fix」vs 表格 11 個 Fix

- L184: 章節標題 `## ScummVM 引擎改動摘要 (累計 9 個 Fix)`
- 同一表格實際列出 **A / B / C / D / E / F / G / G2 / H / I / J = 11 個 Fix**
- L273: 致謝段又寫「我們的 ScummVM fork branch (含 iter1-9 全部 **11** 個 Fix)」← 此處正確
- L73: `## 中文化進度 (累計 9 個 iter)` ← 但表格末 iter 為 iter9/iter10，且 Fix J = iter7、「iter10 用 load-time substitution」(L44) 表示已有 iter10 規劃

**建議修正**:
- 把 L184 改成 `## ScummVM 引擎改動摘要 (累計 11 個 Fix)`；或如 G2 視為 G 的子修正則拿掉表格列 G2 row、並在 G 描述加 "(含 3 處 OOB gate)"
- L73 寫「累計 9 個 iter」可保留 (因 iter10 確實 still 規劃中)，但 L276「9 個 iter 全程用 Claude Code」與 L73 並無衝突，可保留

### Minor issues

#### M1. TOC 缺失
README 達 288 行、12+ 大章節，但無頂部目錄。建議加 8 行 TOC 在 L11 與「關於《魔眼殺機 1》」之間，提升 GitHub repo 首頁可掃描性。

#### M2. 「累計 9 個 iter」與「11 個 Fix」對齊的提法
L73 / L184 / L273 三處 iter 數 vs fix 數混用易讀者困惑。建議統一用語: **iter** 指測+修+驗證循環次數 (9 次)、**Fix** 指引擎 patch 點 (11 處)；可加一句註腳「1 iter 內可含多個 Fix (如 iter1 一次 ship A/B/C 三 Fix)」。

#### M3. 致謝段「11 個 Fix」前後不對齊
L273 寫「11 個 Fix」是對的，但因 L184 章節標題寫「9 個」，讀者讀到致謝段才發現對不上。修 C1 後此 M3 自動消解。

#### M4. translations/level_messages.md 內部尚有「Waterdeep」未中文化
README 已全 repo 把 "水深市" 改成 "深水城"，但 `translations/level_messages.md` L37 章節標題仍寫:
```
### LEVEL1.INF (Waterdeep 下水道入口)
```
此檔被 README L84 / L112 / L216 引用，建議跟進改成「深水城下水道入口」維持一致。**注意**: 此問題不在 README 本身，僅是 README 引用的下游檔案，但為譯名統一計建議一併修。

#### M5. 「為何中文化」段稍可加 1990s 中文化生態 context
L37-40 提到 EOB2 中文版 (隱月傳奇) 1990s 中後期完成，但未說明 EOB2 ZH 與 EOB1 為何脫鉤 (技術差異？商業考量？)。可加 1 行解釋讓非中文 RPG fan 也讀得懂。**選用 minor**。

#### M6. 「ScummVM (~2015 起)」 措辭模糊
L39 寫「ScummVM (~2015 起) 將原 DOS 二進位逆向重寫」— 實際上 KyraEngine 在 ScummVM tree 內 commit 約 2009-2010 (rich_evolved)，EOB engine 約 2012。`~2015` 偏晚。建議改成「ScummVM (2009 起逐步加入 KYRA engine, 2012 加入 EOB)」或直接說「ScummVM 的 KYRA engine」省略年份。**事實準確性 minor**。

#### M7. License 段缺 BoutiqueBitmap9x9 上游 link
L268 致謝段有 link，但 L222 license 段只寫「BoutiqueBitmap9x9 字模: OFL 1.1」未連結。建議補上 https://github.com/scott0107000/BoutiqueBitmap9x9 與 SIL OFL 1.1 license 全文 URL。

---

## 文法/typo (Step 4)

掃 README 全文 288 行，發現:

| 行號 | 問題 | 嚴重度 |
|---|---|---|
| L14 | 「採用 AD&D 第二版規則 (Advanced Dungeons & Dragons 2nd Edition)」— 嚴格說 EOB1 (1991) 採 **AD&D 1e** 或 1989 過渡到 2e 的混合，**非純 2e**。考據黨會挑刺。建議改「採用 AD&D 規則 (1989 2nd Edition 過渡期)」或直接寫「AD&D 第二版規則」並加註「(早期 2e, 1989 規則書)」 | 事實 |
| L18 | "**委任狀及私掠許可**" — Letter of Marque 一般中譯「私掠許可證」， "委任狀" 字面是 Commission；組合「委任狀及私掠許可」語意對但拗口。建議「委任狀與私掠許可證」(加「證」字) | 譯名 |
| L34 | "(Anya, Beohram, Kirath, Ileira, Tyrra, Tod) 加入隊伍 (隊伍最大 6 人)" — 列了 6 名但 EOB1 partly 最多招募 2 個 NPC (隊伍上限 6 人 = 4 原始 + 2 NPC)。「6 人」這數字會被誤解。建議「(隊伍最大 6 人，4 個原始 + 至多 2 個招募 NPC)」 | 表達 |
| L44 | "iter10 用 **load-time substitution table** 處理 (參考 u6-cht 顯示時查表方案)" — load-time vs 顯示時 (display-time) 並不完全等價。u6-cht 是 **display-time substitution** (見 L248 章節標題)，本句寫 load-time 是用詞錯誤。建議改 "iter10 用 **display-time substitution table** 處理" 與 L248 一致 | 用詞 |
| L268 | "BoutiqueBitmap9x9 TTF" — 嚴格上 BoutiqueBitmap9x9 是 bitmap font 不是 TTF (or 它打包成 TTF wrapper)。若是後者可標明 "(bitmap font in TTF wrapper)" | 細節 |
| L93 | "工具/武器/防具/魔法/任務道具" — 與 items.md 章節 (介面/武器/武器擲投/武器具名魔法/防具/防具種族具名/法術器具/飾品/鑰匙) 不完全對應。建議跟 items.md 章節同步: 「介面 / 武器 / 擲投武器 / 具名魔法武器 / 防具 / 種族特用防具 / 法術器具 / 飾品 / 鑰匙」 | 一致性 |
| L73 | 全形括號用法不一致 — 本表標題用「(累計 9 個 iter)」半形括號，但 L26 / L33 也是半形 (Beholder 巢穴 / Anya, Beohram...) — 全文整體採半形 OK 但 L31 「(memorize)」 vs L30 「(e.g. 戰／法、戰法盜)」 中英括號內偶有不一致 | 微小 |
| L215 | "從 `EOBDATA3.PAK` 的 `TEXT.DAT` 抽 51 條，全翻" — 「全翻」較口語，正式寫法可作「全數翻譯」。**極小** | 風格 |
| L221 | "我們的 patches (engine + ZH provider strings + Python tools): GPLv3+" — 應補一行說明 ZH provider 內的字串是衍生於 ScummVM Kyra engine struct 因此 GPL；但 NPC dialogue 等翻譯文字本身在原 EOB1 game data 屬於 Westwood/SSI，**翻譯衍生作品的 license 模糊區**。考究的 license 律師會挑刺。建議補一句 "(NPC dialogue / item names 翻譯為 derivative work，僅在 user 自備合法 EOB1 之 fair-use 範疇分發)" | License 嚴謹度 |

---

## 結構審查

| 章節 | 順序 | 評估 |
|---|---|---|
| 標題 + 作者 + repo URL | L1-10 | OK，作者資訊完整 (姓名/角色/起始日期/repo URL/姊妹專案) |
| 關於《魔眼殺機 1》(故事背景 / 機制亮點 / 為何中文化) | L12-40 | **新增章節品質 A**，敘述清晰，事實大致準確 (年代/發行商正確)，**但 L14 AD&D 2e、L18 Letter of Marque 譯法、L34 NPC 6 人需微修** |
| 現況一句話 | L42-46 | OK，雙擊 .bat 即玩很 user-friendly |
| Screenshots (5 張) | L48-71 | OK，5 張都有對應 Fix 說明 |
| 中文化進度表 (12 行) | L73-87 | OK，但 L73 「9 個 iter」需與 L184「9 個 Fix」一起重新校對 |
| 挖掘原始內容 (物品/對話/LEVEL.INF) | L89-112 | OK，與 translations/*.md 數字同步 |
| 目錄 (tree) | L114-154 | OK，反映實際 repo 結構 |
| 快速開始 (玩遊戲) | L156-165 | OK |
| 開發 (WSL build) | L167-182 | OK |
| 引擎改動摘要 (11 fix) | L184-200 | **C1 critical: 章節標題寫「9 個 Fix」但表格 11 列** |
| 字模 | L202-210 | OK，13,751 字數字與 L85 一致 |
| 翻譯來源 | L212-216 | OK |
| License | L218-225 | **M7 minor: BoutiqueBitmap9x9 缺上游 link，license 嚴謹度可加強** |
| repo URL + clone | L227-234 | OK |
| 還沒做的 | L236-246 | OK |
| 設計理念 (display-time substitution) | L248-261 | OK，與 u6-cht 方法論對齊 |
| 致謝 (3 子段) | L263-281 | OK，涵蓋面完整 (ScummVM / EOB2 ZH / 字模 / D&D 圈 / 姊妹專案 / AI co-author) |
| Reverse engineering 工作 | L283-288 | OK，但 L283 在 L281 致謝段後仍歸於致謝是否合適？建議獨立成 `## 技術文件` 或合併到 L114-154 目錄章節 |

---

## 致謝完整性檢查 (Step 4-5)

| 應涵蓋對象 | README 是否致謝 |
|---|---|
| ScummVM 團隊 (engine + Big5Font + KyraEngine) | YES L266 |
| EOB2 ZH 隱月傳奇 (CHINFONT 字模 + ZH layout 上游) | YES L267 |
| BoutiqueBitmap9x9 字模 (940 字補) | YES L268 |
| 1990s 中文 D&D RPG 圈 (術語慣例) | YES L269 |
| u6-cht (姊妹專案 / 方法論原始 codebase) | YES L272 |
| ScummVM fan-translation fork branch | YES L273 |
| Claude Code AI co-author + 4 sub-agent | YES L275-279 |
| Reverse engineering 工作 (PAK/TEXT.DAT/ITEM.DAT/ceob.pat 格式) | YES L283-288 |

**致謝完整 — PASS**。

---

## 版權聲明檢查 (Step 4-6)

L225 明確聲明:
> "原 EOB1 (Westwood/SSI 1991) 之遊戲執行檔、PAK、ITEM.DAT、TEXT.DAT、LEVEL.INF 等內容**不入此 repo**。執行本中文化需 player 自備合法 EOB1 安裝 (建議 Steam ...)"

L165 也說「沒有 EOB1? 請從 Steam 購買 ... 取得合法授權」。

**版權聲明清楚 — PASS**。

---

## 結論與建議

### 整體品質: **A-**

README 大改後 (新增「關於《魔眼殺機 1》」+ 譯名統一) 達到 **A-** 等級:
- 故事敘述章節**結構清晰、事實大致正確** (僅 AD&D 2e / Letter of Marque 譯法 / NPC 數字 3 處需微修)
- **譯名統一徹底** (3 處「深水城」, 0 處「水深市」)
- 截圖 + translations/ 連結 100% 可達
- 致謝涵蓋完整 (8 個面向全有)
- 版權聲明清楚 (user 自備授權 + Steam 推薦)

### 距離 A 還差什麼

1. **(Critical) C1: 9 vs 11 Fix 計數不一致** — 必修，5 min 內可改 (L184 章節標題)
2. **(Minor) M4: level_messages.md 內 Waterdeep 中文化** — 譯名統一 last mile
3. **(Minor) M1: 加 TOC** — GitHub repo 首頁讀者體驗 +50%
4. **(Typo/事實) L14 AD&D 2e + L18 Letter of Marque + L34 NPC 數字 + L44 load-time→display-time** — 4 處 1-2 字微修

### Ship/Push 建議

**建議: 先修 Critical (C1) + M4 + L44 (load-time → display-time) 再 push**，總共 5 分鐘可完成。其他 Minor 可進 issue list 後續 polish。**目前狀態 ship 也勉強 OK** (整體 A-，無 blocker)，但既然 review 找出 1 個 critical 數字錯誤、建議至少修這條再 push。

修完後預期等級提升到 **A** (or A+，若同時做 TOC + license 補 link)。
