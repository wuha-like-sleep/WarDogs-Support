#!/usr/bin/env python3
"""把模拟器原始截图合成上架截图（顶部文案 + 圆角设备图）。

用法：先用 simctl 截出 raw-01..04.png 放进 --dir，再跑这个脚本。
放进仓库是因为它丢过一次 —— 原来在 /tmp 里，被系统清掉了。
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFont

BG = (11, 14, 19)
WHITE = (240, 242, 245)
DIM = (150, 158, 168)
FONT = '/System/Library/Fonts/Hiragino Sans GB.ttc'  # PingFang 那几个 index 渲不出中文

SHOTS = [
    ('raw-01.png', '报坐标，出诸元', '队友喊一串数字，距离和方向立刻在屏幕上'),
    ('raw-04.png', '打三级甲用哪把枪', '选弹药和护甲等级，直接排出来'),
    ('raw-03.png', '枪械资料随手查', '搜名字、按分类翻，断网照样用'),
    ('raw-02.png', '载具、兵种、机制', '一局里要知道的事，都在本地'),
]


def compose(src_dir, out_dir, canvas, title_px, sub_px, shot_ratio, top, radius):
    W, H = canvas
    os.makedirs(out_dir, exist_ok=True)
    for i, (src, title, sub) in enumerate(SHOTS, 1):
        path = os.path.join(src_dir, src)
        if not os.path.exists(path):
            print(f'  跳过 {src}（没有这张）')
            continue
        c = Image.new('RGB', (W, H), BG)
        d = ImageDraw.Draw(c)

        def center(y, text, px, fill):
            f = ImageFont.truetype(FONT, px, index=1)
            b = d.textbbox((0, 0), text, font=f)
            d.text(((W - (b[2] - b[0])) // 2, y), text, font=f, fill=fill)

        center(int(H * 0.052), title, title_px, WHITE)
        center(int(H * 0.112), sub, sub_px, DIM)

        shot = Image.open(path)
        sw = int(W * shot_ratio)
        sh = int(shot.height * sw / shot.width)
        shot = shot.resize((sw, sh), Image.LANCZOS)
        mask = Image.new('L', (sw, sh), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1],
                                               radius=radius, fill=255)
        x = (W - sw) // 2
        d.rounded_rectangle([x - 3, top - 3, x + sw + 2, top + min(sh, H - top) + 2],
                            radius=radius + 3, outline=(46, 54, 66), width=3)
        c.paste(shot, (x, top), mask)
        c.save(os.path.join(out_dir, f'{i:02d}.png'))
        print(f'  {i:02d}.png  {title}')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--ipad', action='store_true')
    a = ap.parse_args()
    if a.ipad:
        compose(a.dir, a.out, (2064, 2752), 118, 58, 0.78, 470, 48)
    else:
        compose(a.dir, a.out, (1320, 2868), 96, 48, 0.80, 430, 54)
