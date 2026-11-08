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
