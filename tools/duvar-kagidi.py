#!/usr/bin/env python3
"""Vabu duvar kağıtlarını üretir: katmanlı sırtlar, alçak ışık, ince gren.

    tools/duvar-kagidi.py            # branding/ altındaki SVG'leri yeniden yazar

Çıktı düz SVG'dir; paket derlenirken rsvg-convert ile PNG'ye çevrilir.
Sırtlar tohumlu gürültüyle çizilir, bu yüzden aynı tohum hep aynı manzarayı verir.
"""
import math
import random
from pathlib import Path

W, H = 3840, 2160
OUT = Path(__file__).resolve().parent.parent / "branding"


class Noise:
    """Tek boyutlu, yumuşak geçişli değer gürültüsü."""

    def __init__(self, seed):
        rnd = random.Random(seed)
        self.v = [rnd.uniform(-1, 1) for _ in range(1024)]

    def at(self, x):
        i = math.floor(x)
        f = x - i
        f = f * f * f * (f * (f * 6 - 15) + 10)
        a, b = self.v[i % 1024], self.v[(i + 1) % 1024]
        return a + (b - a) * f

    def fbm(self, x, octaves, lacunarity=2.0, gain=0.5):
        amp, freq, total, norm = 1.0, 1.0, 0.0, 0.0
        for _ in range(octaves):
            total += amp * self.at(x * freq)
            norm += amp
            amp *= gain
            freq *= lacunarity
        return total / norm


def ridge(seed, base, height, scale, octaves, sharp=0.6):
    """Bir sırtın üst çizgisi. base: ortalama yükseklik (y), height: genlik (px).
    sharp: 0 yumuşak tepeler, 1 keskin sırtlar."""
    n = Noise(seed)
    m = Noise(seed + 101)
    pts = []
    for x in range(0, W + 1, 6):
        t = x / W
        u = t * scale + seed * 3.7
        # sırt gürültüsü: her oktavda |gürültü| ters çevrilir, tepeler sivrilir
        amp, freq, total, norm = 1.0, 1.0, 0.0, 0.0
        for _ in range(octaves):
            v = n.at(u * freq)
            total += amp * ((1 - abs(v)) * 2 - 1)
            norm += amp
            amp *= 0.5
            freq *= 2.03
        ridged = total / norm
        smooth = m.fbm(u * 0.9 + 13.1, max(2, octaves - 1))
        # geniş ölçekli dalga: sırt bir yanda yükselir, bir yanda alçalır
        swell = m.fbm(t * scale * 0.35 + 5.3, 2)
        y = base - height * (sharp * ridged + (1 - sharp) * smooth) - height * 0.9 * swell
        pts.append((x, y))
    return f"M0 {H} L0 {pts[0][1]:.1f} " + " ".join(f"L{x} {y:.1f}" for x, y in pts) + f" L{W} {H} Z"


def stars(seed, count, max_y):
    rnd = random.Random(seed)
    out = []
    for _ in range(count):
        x, y = rnd.uniform(0, W), rnd.uniform(0, max_y) ** 1.0
        r = rnd.choice([1.2, 1.4, 1.6, 2.0, 2.6])
        o = rnd.uniform(0.15, 0.8) * (1 - y / max_y) ** 0.6
        out.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r}" fill="#fff" opacity="{o:.2f}"/>')
    return "\n".join(out)


def scene(name, sky, sun, layers, star_count=0, grain=0.06, seed=3):
    """sky: [(konum, renk)], sun: (x, y, yarıçap, renk, hale rengi, hale yarıçapı),
    layers: uzaktan yakına [(base, height, scale, octaves, üst renk, alt renk, keskinlik)]"""
    stops = "\n".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in sky)
    sx, sy, sr, sc, glow, gr = sun
    defs = [f'<linearGradient id="sky" x1="0" y1="0" x2="0" y2="{H}" gradientUnits="userSpaceOnUse">{stops}</linearGradient>',
            f'<radialGradient id="glow" cx="{sx}" cy="{sy}" r="{gr}" gradientUnits="userSpaceOnUse">'
            + "".join(f'<stop offset="{o:.3f}" stop-color="{glow}" stop-opacity="{0.92 * math.exp(-(o * 3.4) ** 1.5) * (1 - o) :.3f}"/>'
                      for o in [i / 16 for i in range(17)])
            + '</radialGradient>',
            f'<filter id="grain" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse">'
            '<feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7" stitchTiles="stitch"/>'
            f'<feColorMatrix type="matrix" values="0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 0 0.5  0 0 0 {grain} 0"/></filter>']
    body = [f'<rect width="{W}" height="{H}" fill="url(#sky)"/>']
    if star_count:
        body.append(stars(seed + 11, star_count, H * 0.55))
    body.append(f'<rect width="{W}" height="{H}" fill="url(#glow)"/>')
    if sr:
        # disk: kenarı havada erir, keskin bir daire gibi durmaz
        defs.append(f'<radialGradient id="disc" cx="{sx}" cy="{sy}" r="{sr * 1.5}" gradientUnits="userSpaceOnUse">'
                    f'<stop offset="0" stop-color="{sc}"/><stop offset="0.6" stop-color="{sc}"/>'
                    f'<stop offset="0.72" stop-color="{sc}" stop-opacity="0.55"/><stop offset="1" stop-color="{sc}" stop-opacity="0"/></radialGradient>')
        body.append(f'<circle cx="{sx}" cy="{sy}" r="{sr * 1.5}" fill="url(#disc)"/>')
    for i, (base, height, scale, octaves, top, bottom, sharp) in enumerate(layers):
        # her sırt yukarıda kendi rengi, aşağıda bir arkadakine karışan sis
        defs.append(f'<linearGradient id="r{i}" x1="0" y1="{base - height * 1.4:.0f}" x2="0" y2="{min(H, base + height * 2.2):.0f}" gradientUnits="userSpaceOnUse">'
                    f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>')
        body.append(f'<path d="{ridge(seed + i * 17, base, height, scale, octaves, sharp)}" fill="url(#r{i})"/>')
    body.append(f'<rect width="{W}" height="{H}" filter="url(#grain)"/>')
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n'
           f'<defs>\n' + "\n".join(defs) + '\n</defs>\n' + "\n".join(body) + '\n</svg>\n')
    (OUT / name).write_text(svg, encoding="utf-8")
    print(f"{name}: {len(svg) // 1024} KB")


# Alacakaranlık: güneş uzak sırtların ardına inerken
scene("wallpaper.svg",
      sky=[(0, "#11131E"), (0.28, "#1F2134"), (0.48, "#3D3550"), (0.62, "#7A5670"), (0.73, "#C07E78"), (0.82, "#E6A985"), (0.9, "#F2C79E"), (1, "#F5D3AC")],
      sun=(2540, 1395, 54, "#FCE9CF", "#F8CFA4", 1500),
      layers=[
          (1465, 85, 3.4, 5, "#B58A8C", "#CFA192", 0.6),
          (1535, 95, 4.0, 6, "#9A7482", "#B58E8C", 0.62),
          (1600, 95, 4.4, 6, "#7D5E70", "#977681", 0.62),
          (1680, 110, 5.0, 6, "#614859", "#7A5F6E", 0.65),
          (1770, 120, 5.6, 6, "#48353F", "#5E4856", 0.66),
          (1870, 130, 6.3, 7, "#33262F", "#44333F", 0.68),
          (1980, 130, 7.2, 7, "#211920", "#2D222B", 0.7),
          (2090, 110, 8.4, 7, "#130F14", "#1A141A", 0.7),
      ],
      star_count=160, seed=5)

# Gece: ay ışığında mavi sırtlar
scene("wallpaper-gece.svg",
      sky=[(0, "#06070C"), (0.4, "#0B0E17"), (0.68, "#141A29"), (0.86, "#202A40"), (1, "#2B3854")],
      sun=(1240, 640, 44, "#EEF1F7", "#A9BAD9", 1150),
      layers=[
          (1495, 90, 3.5, 5, "#2B3854", "#394868", 0.6),
          (1570, 90, 3.9, 5, "#243048", "#2F3C59", 0.6),
          (1650, 105, 4.6, 6, "#1D273B", "#27324A", 0.63),
          (1740, 115, 5.3, 6, "#171F30", "#1F293D", 0.66),
          (1840, 125, 6.0, 6, "#111826", "#182031", 0.68),
          (1950, 130, 6.9, 7, "#0C111B", "#111825", 0.7),
          (2070, 115, 8.0, 7, "#07090F", "#0A0D15", 0.7),
      ],
      star_count=560, seed=12)

# Gündüz: açık görünümün duvar kağıdı. Soluk mavi sırtlar, ufukta sıcak bir ışık.
scene("wallpaper-gunduz.svg",
      sky=[(0, "#8EA8CB"), (0.34, "#B4C5DC"), (0.6, "#DDD9DC"), (0.8, "#F0E2D8"), (1, "#F6E9DC")],
      sun=(2693, 1067, 0, "#FFFFFF", "#FFF6E8", 1707),
      layers=[
          (1469 + i * 99, 72 + i * 9, 3.3 + i * 0.75, 5 if i < 2 else 6, top, bottom, 0.58 + i * 0.02)
          for i, (top, bottom) in enumerate([
              ("#C5CEDB", "#DADEE4"), ("#AFBBCD", "#C6CEDA"), ("#98A7BD", "#B0BCCC"), ("#8193AC", "#9AA9BD"),
              ("#6B7E99", "#8496AD"), ("#566A86", "#6E8099"), ("#43566F", "#586B84")])
      ],
      grain=0.05, seed=21)
