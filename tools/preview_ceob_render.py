"""Render preview PNG of newly built 14×12 ceob.pat."""
import struct
from pathlib import Path
from PIL import Image, ImageDraw

PAT = Path("/mnt/d/03_game_tmp/eob1_cht/win64-build/game/ceob.pat")
OUT = Path("/mnt/d/03_game_tmp/eob1_cht/test-reports/font-preview/preview_14x12_render.png")

WIDTH = 16
HEIGHT = 12

def load_pat(path):
    data = path.read_bytes()
    g = {}
    i = 0
    while i + 2 <= len(data):
        cp = (data[i] << 8) | data[i+1]
        if cp == 0xFFFF: break
        i += 2
        bm = data[i:i + 2*HEIGHT]
        i += 2*HEIGHT
        g[cp] = bm
    return g

def cp950_to_cps(s):
    raw = s.encode("cp950"); out=[]; i=0
    while i < len(raw):
        b = raw[i]
        if b >= 0xA1:
            out.append((b<<8)|raw[i+1]); i+=2
        else:
            out.append(None); i+=1
    return out

def draw_bm(d, bm, x, y, scale, w=WIDTH):
    for r in range(HEIGHT):
        b = (bm[r*2]<<8) | bm[r*2+1]
        for c in range(w):
            if b & (0x8000 >> c):
                d.rectangle([x+c*scale, y+r*scale, x+(c+1)*scale-1, y+(r+1)*scale-1], fill=(255,255,255))

def main():
    glyphs = load_pat(PAT)
    samples = [
        "偵測魔法 魔法飛彈 魔法盾 電擊",
        "化解魔法 火球術 保護術",
        "騰寫卷軸 偏好設定 遊戲選項",
        "營：休息隊伍 記憶法術 祈禱法術",
        "可用法術 1-5  剩 0/2",
        "中止 離開 清空 確認",
        "鬱鱉龜麟覆譁顯鑰葬囓",
        "皮甲 長袍 法杖 短劍 法術書",
        "乾糧 鎖鏈甲 板甲 長劍 短弓",
    ]
    SCALE = 5
    LINE_H = HEIGHT*SCALE + 4
    img = Image.new("RGB", (1200, 50 + LINE_H*len(samples) + 20), (24,28,40))
    d = ImageDraw.Draw(img)
    d.text((20, 8), f"ceob 14×12 preview (Mingti2L Big5 rendered, {len(glyphs)} glyphs)", fill=(255,220,120))
    y = 36
    for s in samples:
        cps = cp950_to_cps(s)
        cx = 20
        for cp in cps:
            if cp is None:
                cx += 8 * SCALE // 2
                continue
            bm = glyphs.get(cp)
            if bm is None:
                d.rectangle([cx, y, cx + WIDTH*SCALE - 1, y + HEIGHT*SCALE - 1], outline=(255,80,80))
            else:
                draw_bm(d, bm, cx, y, SCALE)
            cx += WIDTH * SCALE
        y += LINE_H
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print(f"Wrote {OUT}")

if __name__ == "__main__":
    main()
