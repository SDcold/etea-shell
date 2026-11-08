#!/usr/bin/env python3
# Draw what stands in each world's sky and on its ground, in flat shapes only: light and
# shade are cut shapes and stepped tones, never a blur. Every shape names a tone from the
# planet's palette instead of a colour, so a world you recolour keeps its scenery in tune.
#
#   world-scenery.py   (writes modules/background/scenery/<World>Art.qml)
#
# A tone is [a], [a, b, t] or [a, b, t, alpha]: a mixed towards b by t. a and b are palette
# names (skyTop, skyMid, skyLow, light, t0 to t3 for the hills from far to near, white,
# night) or plain #rrggbb. Sizes are in the shell's 1600-wide units. The same seed draws the
# same worlds every time.
import math
import random
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "modules", "background", "scenery")


def f(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


def poly(pts):
    return "M" + " L".join(f"{f(x)} {f(y)}" for x, y in pts) + " Z"


# A smooth closed outline through points, Catmull-Rom turned into cubic Béziers
def smooth(pts):
    n = len(pts)
    d = f"M{f(pts[0][0])} {f(pts[0][1])}"
    for i in range(n):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{f(c1[0])} {f(c1[1])} {f(c2[0])} {f(c2[1])} {f(p2[0])} {f(p2[1])}"
    return d + " Z"


def circle(cx, cy, r):
    return f"M{f(cx - r)} {f(cy)}a{f(r)} {f(r)} 0 1 0 {f(2 * r)} 0a{f(r)} {f(r)} 0 1 0 {f(-2 * r)} 0Z"


def ellipse_pts(cx, cy, a, b, t0, t1, n, tilt=0.0):
    pts = []
    for i in range(n + 1):
        t = t0 + (t1 - t0) * i / n
        x, y = a * math.cos(t), b * math.sin(t)
        pts.append((cx + x * math.cos(tilt) - y * math.sin(tilt), cy + x * math.sin(tilt) + y * math.cos(tilt)))
    return pts


# A band between two ellipses sharing a centre, from t0 to t1 along them
def ellipse_band(cx, cy, a0, b0, a1, b1, t0, t1, tilt=0.0, n=64):
    outer = ellipse_pts(cx, cy, a1, b1, t0, t1, n, tilt)
    inner = ellipse_pts(cx, cy, a0, b0, t0, t1, n, tilt)
    return poly(outer + inner[::-1])


# The lit side's edge on a ball, as a crescent of shade on the far side. Wider crescents
# stack into stepped shading.
def crescent(cx, cy, r, depth, side=-1, n=40):
    arc = [(cx + side * r * math.sin(t), cy - r * math.cos(t)) for t in [math.pi * i / n for i in range(n + 1)]]
    term = [(cx + side * r * depth * math.sin(t), cy - r * math.cos(t)) for t in [math.pi * i / n for i in range(n + 1)]]
    return poly(arc + term[::-1])


# A horizontal strip of a disc, its edges waving a little like a gas giant's bands
def disc_band(cx, cy, r, y0, y1, wave, phase, n=28):
    def edge(y, k):
        return y + wave * math.sin(k * 0.035 + phase)
    left, right = [], []
    top, bottom = [], []
    for i in range(n + 1):
        x = cx - r + 2 * r * i / n
        top.append((x, edge(y0, x)))
        bottom.append((x, edge(y1, x)))
    pts = []
    for x, y in top:
        lim = math.sqrt(max(0.0, r * r - (x - cx) ** 2))
        pts.append((x, min(max(y, cy - lim), cy + lim)))
    for x, y in bottom[::-1]:
        lim = math.sqrt(max(0.0, r * r - (x - cx) ** 2))
        pts.append((x, min(max(y, cy - lim), cy + lim)))
    return poly(pts)


def blob(cx, cy, rx, ry, rnd, n=10, jitter=0.25):
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n + rnd.uniform(-0.15, 0.15)
        s = rnd.uniform(1 - jitter, 1 + jitter * 0.4)
        pts.append((cx + math.cos(t) * rx * s, cy + math.sin(t) * ry * s))
    return smooth(pts)


# A long flat lens of cloud or mist, flatter underneath than on top
def lens(cx, cy, w, h, rnd, bumps=5):
    pts = []
    for i in range(bumps + 1):
        x = cx - w / 2 + w * i / bumps
        lift = math.sin(math.pi * i / bumps) ** 0.7
        pts.append((x, cy - h * lift * rnd.uniform(0.75, 1.15)))
    for i in range(bumps, -1, -1):
        x = cx - w / 2 + w * i / bumps
        pts.append((x, cy + h * 0.35 * math.sin(math.pi * i / bumps)))
    return smooth(pts[:-1])


def part(w, h, *layers):
    return {"w": w, "h": h, "layers": [{"tone": tone, "d": d, **({"evenOdd": True} if odd else {})} for tone, d, odd in layers]}


def L(tone, d, odd=False):
    return (tone, d, odd)


def moon(r, body, shade, rnd, craters=0, crater_tone=None):
    c = r + 2
    layers = [L(body, circle(c, c, r))]
    for _ in range(craters):
        a, d = rnd.uniform(0, 2 * math.pi), rnd.uniform(0, r * 0.6)
        layers.append(L(crater_tone, circle(c + math.cos(a) * d, c + math.sin(a) * d, rnd.uniform(r * 0.08, r * 0.2))))
    layers.append(L(shade, crescent(c, c, r, 0.45)))
    layers.append(L(shade, crescent(c, c, r, 0.85)))
    return part(2 * c, 2 * c, *layers)


worlds = {}

# Aster takes after Saturn: from one of its moons, the ringed giant never quite sets
rnd = random.Random(3)
R = 230
W2, H2 = 2 * 470, 2 * 240
cx, cy = W2 / 2, H2 / 2
tilt = -0.2
ring = [(1.42, 1.62, ["light", "skyLow", 0.35, 0.8]), (1.68, 2.0, ["light", "skyMid", 0.25, 0.7])]
back, front = [], []
for a0, a1, tone in ring:
    back.append(L(tone, ellipse_band(cx, cy, R * a0, R * a0 * 0.2, R * a1, R * a1 * 0.2, math.pi, 2 * math.pi, tilt)))
    front.append(L(tone, ellipse_band(cx, cy, R * a0, R * a0 * 0.2, R * a1, R * a1 * 0.2, 0, math.pi, tilt)))
globe = [L(["skyLow", "light", 0.25], circle(cx, cy, R))]
tones = [["skyMid", "light", 0.35], ["skyLow", "light", 0.55], ["skyMid", "skyLow", 0.5], ["skyMid", "t0", 0.3], ["skyLow", "skyMid", 0.3]]
y = cy - R
k = 0
while y < cy + R:
    step = rnd.uniform(26, 58)
    globe.append(L(tones[k % len(tones)], disc_band(cx, cy, R, y, y + step * 0.6, rnd.uniform(2, 6), rnd.uniform(0, 6))))
    y += step
    k += 1
# The hexagon around its pole, seen almost edge-on
hexa = [(cx + 46 * math.cos(math.pi / 3 * i + 0.3), cy - R * 0.87 + 13 * math.sin(math.pi / 3 * i + 0.3)) for i in range(6)]
inner = [(cx + (x - cx) * 0.82, cy - R * 0.87 + (y - (cy - R * 0.87)) * 0.82) for x, y in hexa]
globe.append(L(["light", "white", 0.4, 0.55], poly(hexa) + " " + poly(inner[::-1]), True))
globe.append(L(["skyTop", "night", 0.2, 0.38], crescent(cx, cy, R, 0.5)))
globe.append(L(["skyTop", "night", 0.35, 0.45], crescent(cx, cy, R, 0.86)))
# The ring's shadow, a dark ribbon across the globe just above where the ring passes
globe.append(L(["skyTop", "night", 0.1, 0.3], ellipse_band(cx, cy + 10, R * 0.98, R * 0.98 * 0.2, R * 1.0, R * 0.26, math.pi * 1.04, math.pi * 1.96, tilt)))
worlds["Aster"] = {
    "ringBack": part(W2, H2, *back),
    "giant": part(W2, H2, *globe),
    "ringFront": part(W2, H2, *front),
    "moonA": moon(9, ["light", "white", 0.5], ["skyTop", "night", 0.3, 0.6], rnd),
    "moonB": moon(5, ["skyLow", "light", 0.5], ["skyTop", "night", 0.3, 0.6], rnd),
    "moonC": moon(3.5, ["light"], ["skyTop", "night", 0.3, 0.6], rnd),
}

# Néré takes after Neptune: its faint ring arcs really are called Liberté, Égalité and
# Fraternité. Triton hangs pale and pink, mist rolls over the swell, and now and then a
# fast white cloud races across, like the one Voyager saw
rnd = random.Random(7)
arcs = part(1600, 300,
    L(["light", "skyMid", 0.4, 0.22], ellipse_band(800, 300, 940, 210, 946, 213, math.pi * 1.02, math.pi * 1.98)),
    L(["light", "white", 0.3, 0.6], ellipse_band(800, 300, 938, 209, 950, 215, math.pi * 1.24, math.pi * 1.33)),
    L(["light", "white", 0.3, 0.55], ellipse_band(800, 300, 938, 209, 949, 214, math.pi * 1.36, math.pi * 1.4)),
    L(["light", "white", 0.3, 0.5], ellipse_band(800, 300, 939, 210, 948, 214, math.pi * 1.43, math.pi * 1.5)))
tri = []
c, r = 30, 26
tri.append(L(["light", "#f6d6d0", 0.5], circle(c, c, r)))
for _ in range(6):
    tri.append(L(["light", "skyMid", 0.25], blob(c + rnd.uniform(-14, 14), c + rnd.uniform(-14, 14), rnd.uniform(3, 7), rnd.uniform(2, 5), rnd)))
tri.append(L(["#fff8f2"], blob(c + 4, c + 14, 12, 7, rnd)))  # the bright southern cap
tri.append(L(["skyTop", "night", 0.25, 0.5], crescent(c, c, r, 0.45)))
tri.append(L(["skyTop", "night", 0.4, 0.6], crescent(c, c, r, 0.85)))
mist = []
for tone, n, (hmin, hmax) in [(["skyLow", "white", 0.25, 0.5], 5, (10, 18)), (["skyMid", "skyLow", 0.55, 0.55], 4, (14, 22))]:
    d = ""
    for i in range(n):
        d += lens(rnd.uniform(100, 1500), rnd.uniform(40, 70), rnd.uniform(300, 620), rnd.uniform(hmin, hmax), rnd) + " "
    mist.append(L(tone, d))
scooter = part(140, 24,
    L(["white", "light", 0.2, 0.9], lens(70, 16, 120, 9, rnd, 4)),
    L(["white", "light", 0.2, 0.6], lens(40, 20, 50, 5, rnd, 3)))
worlds["Nere"] = {"arcs": arcs, "triton": part(60, 60, *tri), "mist": part(1600, 90, *mist), "scooter": scooter}

# Ocre takes after Mars: Olympus Mons on the horizon, a sunset that turns blue around the
# sun, Phobos rising in the west and racing across, Deimos crawling, and dust everywhere
rnd = random.Random(5)
pts = []
for i in range(41):
    x = i / 40
    h = (1 - abs(2 * x - 1) ** 1.6) * 74
    if 0.46 < x < 0.54:
        h -= 7 * math.cos((x - 0.5) / 0.04 * math.pi / 2)  # the caldera
    pts.append((40 + x * 920, 90 - h))
flank = [(x, y) for x, y in pts if x >= 500]
olympus = part(1000, 92,
    L(["t0", "skyLow", 0.55], poly(pts + [(960, 92), (40, 92)])),
    L(["t0", "light", 0.45], poly(flank + [(960, 92), (500, 92)])),
    L(["t0", "skyLow", 0.35], poly([(x, y + 14) for x, y in pts[4:37]] + [(880, 92), (120, 92)])))
halo = [L(["#9fc5ec", "skyLow", t, a], circle(90, 90, r)) for r, t, a in [(86, 0.75, 0.3), (62, 0.55, 0.4), (42, 0.35, 0.5), (26, 0.15, 0.7)]]
halo.append(L(["white", "light", 0.25], circle(90, 90, 10)))
phobos = part(40, 30,
    L(["t1", "skyLow", 0.35], blob(20, 15, 16, 11, rnd, 9, 0.18)),
    L(["t2", "t1", 0.4], circle(13, 13, 4)),
    L(["t2", "t1", 0.5], circle(25, 18, 2)),
    L(["skyTop", "night", 0.3, 0.55], crescent(20, 15, 15, 0.4)))
deimos = part(20, 16, L(["t1", "skyLow", 0.5], blob(10, 8, 8, 6, rnd, 8, 0.15)), L(["skyTop", "night", 0.3, 0.5], crescent(10, 8, 7, 0.35)))
dust = []
for tone, n, size in [(["light", "skyLow", 0.4, 0.4], 60, (1.2, 2.4)), (["t0", "skyLow", 0.5, 0.35], 34, (2, 4))]:
    d = ""
    for _ in range(n):
        x, y = rnd.uniform(0, 1600), 120 - 120 * rnd.random() ** 1.6
        w = rnd.uniform(*size)
        d += f"M{f(x - w * 2.4)} {f(y)}a{f(w * 2.4)} {f(w * 0.5)} 0 1 0 {f(w * 4.8)} 0a{f(w * 2.4)} {f(w * 0.5)} 0 1 0 {f(-w * 4.8)} 0Z "
    dust.append(L(tone, d))
devil = []
for i in range(9):
    t = i / 8
    w, y = 8 + 30 * t ** 1.4, 170 - t * 160
    devil.append(L(["t0", "light", 0.25 + 0.3 * (i % 2), 0.32 + 0.1 * (1 - t)], f"M{f(40 + 12 * t - w)} {f(y)}a{f(w)} {f(w * 0.28)} 0 1 0 {f(2 * w)} 0a{f(w)} {f(w * 0.28)} 0 1 0 {f(-2 * w)} 0Z"))
worlds["Ocre"] = {"olympus": olympus, "sun": part(180, 180, *halo), "phobos": phobos, "deimos": deimos, "dust": part(1600, 124, *dust), "devil": part(90, 180, *devil)}

# Vesper takes after Venus: flat round volcanoes, clouds turning faster than the ground,
# lightning inside them, and up there a tiny blue star with its moon: home
rnd = random.Random(9)
clouds = []
# From the lowest hem up, so each layer's hem shows under the one above it
for i, (tone, top, depth) in enumerate([(["skyMid", "light", 0.14], 130, 60), (["skyMid", "skyTop", 0.3], 60, 90), (["skyTop", "skyMid", 0.55], 0, 120)]):
    pts = [(0, top - 40)]
    x = 0
    while x < 1600:
        step = rnd.uniform(70, 150)
        pts.append((x + step / 2, top + depth + rnd.uniform(6, 22)))
        x += step
        pts.append((x, top + depth - rnd.uniform(0, 10)))
    pts[-1] = (1600, pts[-1][1])
    pts.append((1600, top - 40))
    # The band wraps around, so it starts where it ends
    d = f"M0 {f(top - 40)} L0 {f(pts[-2][1])}"
    for j in range(1, len(pts) - 2, 2):
        mid, end = pts[j], pts[j + 1]
        d += f" Q{f(mid[0])} {f(mid[1])} {f(end[0])} {f(end[1])}"
    d += f" L1600 {f(top - 40)} Z"
    clouds.append(L(tone, d))
bolt = [(30, 0), (22, 26), (32, 28), (18, 58), (30, 60), (12, 96), (40, 52), (28, 50), (42, 24), (32, 22), (40, 0)]
domes = []
for x0, w, h in [(10, 340, 44), (300, 210, 28), (1250, 250, 34), (1440, 380, 52)]:
    top = 80 - h
    domes.append(L(["t2", "t1", 0.35], f"M{f(x0)} 80 C{f(x0 + w * 0.08)} {f(top)} {f(x0 + w * 0.2)} {f(top)} {f(x0 + w / 2)} {f(top)} C{f(x0 + w * 0.8)} {f(top)} {f(x0 + w * 0.92)} {f(top)} {f(x0 + w)} 80 Z"))
    domes.append(L(["t1", "light", 0.45], f"M{f(x0 + w * 0.14)} {f(top + 3)} C{f(x0 + w * 0.2)} {f(top)} {f(x0 + w * 0.8)} {f(top)} {f(x0 + w * 0.86)} {f(top + 3)} C{f(x0 + w * 0.7)} {f(top + 1.6)} {f(x0 + w * 0.3)} {f(top + 1.6)} {f(x0 + w * 0.14)} {f(top + 3)} Z"))
    domes.append(L(["t3", "night", 0.2, 0.7], f"M{f(x0)} 80 C{f(x0 + w * 0.08)} {f(top)} {f(x0 + w * 0.16)} {f(top + 1)} {f(x0 + w * 0.3)} {f(top + 2)} C{f(x0 + w * 0.22)} {f(top + h * 0.5)} {f(x0 + w * 0.2)} {f(80)} {f(x0 + w * 0.24)} 80 Z"))
worlds["Vesper"] = {
    "clouds": part(1600, 260, *clouds),
    "flash": part(1600, 260, L(["light", "white", 0.3, 0.3], clouds[1][1])),
    "bolt": part(56, 100, L(["white", "light", 0.25], poly(bolt))),
    "domes": part(1850, 82, *domes),
    "home": part(16, 10, L(["#a9d4ff"], circle(5, 5, 3.2)), L(["#e8eef7"], circle(12.5, 4, 1.3))),
}


def qml(value, indent=0):
    pad = "    " * indent
    if isinstance(value, dict):
        inner = ",\n".join(f"{pad}    {k}: {qml(v, indent + 1)}" for k, v in value.items())
        return "{\n" + inner + "\n" + pad + "}"
    if isinstance(value, list):
        if all(not isinstance(v, (dict, list)) for v in value):
            return "[" + ", ".join(qml(v) for v in value) + "]"
        return "[\n" + ",\n".join(pad + "    " + qml(v, indent + 1) for v in value) + "\n" + pad + "]"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return '"' + value + '"'
    return f"{value:.3g}" if isinstance(value, float) else str(value)


os.makedirs(OUT, exist_ok=True)
for name, parts in worlds.items():
    body = "\n\n".join(f"    readonly property var {key}: ({qml(value, 1)})" for key, value in parts.items())
    open(os.path.join(OUT, f"{name}Art.qml"), "w").write(
        f"import QtQuick\n\n// Drawn by scripts/world-scenery.py, run it again rather than editing this by hand.\nQtObject {{\n{body}\n}}\n")
    print(name, sum(len(l["d"]) for p in parts.values() for l in p["layers"]), "chars")
