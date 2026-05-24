import struct
from pathlib import Path
from PIL import Image, ImageDraw

PAT = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob_16x15.pat")
OUT = Path("/mnt/d/03_game_tmp/eob1_cht/test-reports/font-preview/preview_16x15_resample.png")
WIDTH = 16
HEIGHT = 15

def load(p):
    d = p.read_bytes(); g = {}; i = 0
    while i+2 <= len(d):
        cp = (d[i]<<8)|d[i+1]
        if cp == 0xFFFF: break
        i += 2; g[cp] = d[i:i+2*HEIGHT]; i += 2*HEIGHT
    return g

def cps(s):
    raw = s.encode("cp950"); out=[]; i=0
    while i<len(raw):
        b=raw[i]
        if b>=0xA1: out.append((b<<8)|raw[i+1]); i+=2
        else: out.append(None); i+=1
    return out

def draw(d, bm, x, y, sc):
    for r in range(HEIGHT):
        bits = (bm[r*2]<<8)|bm[r*2+1]
        for c in range(WIDTH):
            if bits & (0x8000>>c):
                d.rectangle([x+c*sc, y+r*sc, x+(c+1)*sc-1, y+(r+1)*sc-1], fill=(255,255,255))

samples = [
    "偵測魔法 魔法飛彈 魔法盾 電擊",
    "化解魔法 火球術 保護術",
    "騰寫卷軸 偏好設定 遊戲選項",
    "營：休息隊伍 記憶法術 祈禱法術",
    "中止施法 離開 清空 確認",
    "鬱鱉龜麟覆譁顯鑰葬囓",
    "皮甲 長袍 法杖 短劍 法術書",
    "乾糧 鎖鏈甲 板甲 長劍 短弓",
]
glyphs = load(PAT)
SC = 5
LH = HEIGHT*SC + 4
img = Image.new("RGB", (1200, 50 + LH*len(samples) + 20), (24,28,40))
dr = ImageDraw.Draw(img)
dr.text((20, 8), f"ceob 16x15 preview (Unifont 16x16 -> 16x15 bicubic resample, {len(glyphs)} glyphs)", fill=(255,220,120))
y = 36
for s in samples:
    cx = 20
    for cp in cps(s):
        if cp is None: cx += 8*SC//2; continue
        bm = glyphs.get(cp)
        if bm: draw(dr, bm, cx, y, SC)
        else: dr.rectangle([cx, y, cx+WIDTH*SC-1, y+HEIGHT*SC-1], outline=(255,80,80))
        cx += WIDTH * SC
    y += LH
OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT)
print(f"Wrote {OUT}")
