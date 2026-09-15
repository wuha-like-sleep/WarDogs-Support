#!/usr/bin/env python3
"""生成应用图标。

纯几何图形：迫击炮弹道抛物线 + 落点准星，暗底金线。
不使用任何游戏美术资源、logo 或第三方商标 —— 这是 README 里
「避免纠纷」第一条的硬约束，改图标时请守住。
"""
import math
import os
from PIL import Image, ImageDraw

BG = (14, 18, 25)        # 和 App 的 C.bg 同一系
GOLD = (224, 178, 74)    # C.gold
GOLD_DIM = (140, 110, 46)

SS = 4  # 超采样倍数，靠缩小获得抗锯齿


def draw_icon(size, bleed=True):
    """bleed=True 画满整块（用于 iOS/安卓传统图标）。"""
    S = size * SS
    im = Image.new('RGB', (S, S), BG)
    d = ImageDraw.Draw(im)

    # --- 弹道抛物线：从左下发射，落到右上准星 ---
    x0, y0 = 0.19 * S, 0.80 * S      # 炮口
    x1, y1 = 0.685 * S, 0.40 * S     # 落点（准星中心）
    peak = 0.17 * S                   # 弹道最高点的高度
    cr = 0.145 * S                    # 准星半径，下面画环也用它

    lw = max(2, int(0.052 * S))
    # 弹道在触到准星外环前就收笔，不要穿进圆里显得乱
    for i in range(401):
        t = i / 400
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t - 4 * peak * t * (1 - t)
        if math.hypot(x - x1, y - y1) < cr * 1.30:
            break
        r = lw / 2
        d.ellipse([x - r, y - r, x + r, y + r], fill=GOLD)

    # --- 炮口：一段短粗的斜管 ---
    ang = math.radians(62)
    tube_len = 0.19 * S
    tw = max(3, int(0.072 * S))
    tx, ty = x0 - math.cos(ang) * tube_len * 0.35, y0 + math.sin(ang) * tube_len * 0.35
    ex, ey = x0 + math.cos(ang) * tube_len * 0.65, y0 - math.sin(ang) * tube_len * 0.65
    steps = 80
    for i in range(steps + 1):
        t = i / steps
        px = tx + (ex - tx) * t
        py = ty + (ey - ty) * t
        r = tw / 2
        d.ellipse([px - r, py - r, px + r, py + r], fill=GOLD_DIM)

    # --- 落点准星：外环 + 四向刻度 + 中心点 ---
    ring = max(2, int(0.044 * S))
    d.ellipse([x1 - cr, y1 - cr, x1 + cr, y1 + cr], outline=GOLD, width=ring)

    tick_in = cr * 1.02
    tick_out = cr * 1.52
    for a in (0, 90, 180, 270):
        rad = math.radians(a)
        sx = x1 + math.cos(rad) * tick_in
        sy = y1 - math.sin(rad) * tick_in
        ex2 = x1 + math.cos(rad) * tick_out
        ey2 = y1 - math.sin(rad) * tick_out
        d.line([sx, sy, ex2, ey2], fill=GOLD, width=ring)

    dot = cr * 0.26
    d.ellipse([x1 - dot, y1 - dot, x1 + dot, y1 + dot], fill=GOLD)

    return im.resize((size, size), Image.LANCZOS)


def draw_adaptive_foreground(size):
    """安卓自适应图标前景：内容必须收在中间 66% 的安全区里，
    否则会被各厂商的形状裁掉。"""
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    inner = int(size * 0.62)
    art = draw_icon(inner).convert('RGBA')
    off = (size - inner) // 2
    # 去掉背景色，只留线条
    px = art.load()
    for y in range(inner):
        for x in range(inner):
            r, g, b, _ = px[x, y]
            if abs(r - BG[0]) < 14 and abs(g - BG[1]) < 14 and abs(b - BG[2]) < 14:
                px[x, y] = (0, 0, 0, 0)
    im.paste(art, (off, off), art)
    return im


if __name__ == '__main__':
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # iOS
    ios = os.path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    ios_sizes = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
    cache = {s: draw_icon(s) for s in ios_sizes}
    import re
    for name in os.listdir(ios):
        if not name.endswith('.png'):
            continue
        path = os.path.join(ios, name)
        w = Image.open(path).size[0]
        if w not in cache:
            cache[w] = draw_icon(w)
        cache[w].save(path)
        print(f'  iOS {name} {w}px')

    # 安卓传统图标
    and_res = os.path.join(root, 'android/app/src/main/res')
    for folder, px in [('mipmap-mdpi', 48), ('mipmap-hdpi', 72),
                       ('mipmap-xhdpi', 96), ('mipmap-xxhdpi', 144),
                       ('mipmap-xxxhdpi', 192)]:
        p = os.path.join(and_res, folder, 'ic_launcher.png')
        draw_icon(px).save(p)
        print(f'  安卓 {folder} {px}px')

    # 安卓自适应图标前景（各 dpi 是 108dp 的对应像素）
    for folder, px in [('mipmap-mdpi', 108), ('mipmap-hdpi', 162),
                       ('mipmap-xhdpi', 216), ('mipmap-xxhdpi', 324),
                       ('mipmap-xxxhdpi', 432)]:
        p = os.path.join(and_res, folder, 'ic_launcher_foreground.png')
        draw_adaptive_foreground(px).save(p)
        print(f'  安卓自适应前景 {folder} {px}px')

    print('\n图标生成完毕')
