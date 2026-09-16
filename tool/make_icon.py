#!/usr/bin/env python3
"""生成应用图标。

方案 C：坐标网格 + 落点十字准星。纯几何图形，
不使用任何游戏美术资源、logo 或第三方商标 ——
这是 README 里「避免纠纷」第一条的硬约束，改图标时请守住。

改完跑一次就会重出全部尺寸：
    python3 tool/make_icon.py
"""
import os
from PIL import Image, ImageDraw

BG = (14, 18, 25)        # 和 App 的 C.bg 同一系
GRID = (40, 48, 60)      # 网格线，压得很暗只当底纹
GOLD = (226, 182, 78)    # C.gold

SS = 4  # 超采样倍数，靠缩小获得抗锯齿


def _draw_core(d, S, cx, cy, scale=1.0, with_grid=True):
    """画准星本体。cx/cy 是中心，scale 用来在自适应图标里缩进安全区。"""
    if with_grid:
        gw = 0.018 * S
        for i in (1, 2, 3):
            p = S * i / 4
            d.line([p, 0.10 * S, p, 0.90 * S], fill=GRID, width=max(1, int(gw)))
            d.line([0.10 * S, p, 0.90 * S, p], fill=GRID, width=max(1, int(gw)))

    r = 0.205 * S * scale
    ring = 0.072 * S * scale
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=GOLD, width=max(1, int(ring)))

    arm = r * 1.78
    aw = 0.054 * S * scale
    d.rounded_rectangle(
        [cx - arm, cy - aw / 2, cx + arm, cy + aw / 2],
        radius=aw / 2, fill=GOLD)
    d.rounded_rectangle(
        [cx - aw / 2, cy - arm, cx + aw / 2, cy + arm],
        radius=aw / 2, fill=GOLD)

    dot = 0.063 * S * scale
    d.ellipse([cx - dot, cy - dot, cx + dot, cy + dot], fill=GOLD)


def draw_icon(size):
    S = size * SS
    im = Image.new('RGB', (S, S), BG)
    d = ImageDraw.Draw(im)
    _draw_core(d, S, S / 2, S / 2)
    return im.resize((size, size), Image.LANCZOS)


def draw_adaptive_foreground(size):
    """安卓自适应图标前景：内容必须收在中间 66% 的安全区里，
    否则会被各厂商的形状裁掉。这里不画网格，只留准星。"""
    S = size * SS
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    _draw_core(d, S, S / 2, S / 2, scale=0.62, with_grid=False)
    return im.resize((size, size), Image.LANCZOS)


if __name__ == '__main__':
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cache = {}

    def icon(px):
        if px not in cache:
            cache[px] = draw_icon(px)
        return cache[px]

    ios = os.path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    for name in sorted(os.listdir(ios)):
        if not name.endswith('.png'):
            continue
        path = os.path.join(ios, name)
        w = Image.open(path).size[0]
        icon(w).save(path)
    print(f'  iOS  {len([n for n in os.listdir(ios) if n.endswith(".png")])} 个尺寸')

    and_res = os.path.join(root, 'android/app/src/main/res')
    for folder, px in [('mipmap-mdpi', 48), ('mipmap-hdpi', 72),
                       ('mipmap-xhdpi', 96), ('mipmap-xxhdpi', 144),
                       ('mipmap-xxxhdpi', 192)]:
        icon(px).save(os.path.join(and_res, folder, 'ic_launcher.png'))
    print('  安卓 5 个 dpi')

    for folder, px in [('mipmap-mdpi', 108), ('mipmap-hdpi', 162),
                       ('mipmap-xhdpi', 216), ('mipmap-xxhdpi', 324),
                       ('mipmap-xxxhdpi', 432)]:
        draw_adaptive_foreground(px).save(
            os.path.join(and_res, folder, 'ic_launcher_foreground.png'))
    print('  安卓自适应前景 5 个 dpi')
    print('图标生成完毕')
