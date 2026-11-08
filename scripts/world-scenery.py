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
    return f"{v:.2f}".rstrip("0").rstrip(".")


def P(x, y):
    return f"{f(x)} {f(y)}"


def poly(pts):
    return "M" + " L".join(P(x, y) for x, y in pts) + " Z"


def circle(cx, cy, r):
    return f"M{f(cx - r)} {f(cy)}a{f(r)} {f(r)} 0 1 0 {f(2 * r)} 0a{f(r)} {f(r)} 0 1 0 {f(-2 * r)} 0Z"


# Every shape here that follows a circle or an ellipse is drawn with true arcs, and where
# two edges meet the meeting point is solved for, so nothing steps, pokes out or leaves
# a seam however far you zoom in.

def ellipse_at(ex, ey, a, b, tilt, t):
    x, y = a * math.cos(t), b * math.sin(t)
    return (ex + x * math.cos(tilt) - y * math.sin(tilt), ey + x * math.sin(tilt) + y * math.cos(tilt))


# An arc of ellipse from t0 to t1 (t growing turns clockwise on screen)
def ellipse_arc(a, b, tilt, t0, t1, end):
    large = 1 if abs(t1 - t0) > math.pi else 0
    sweep = 1 if t1 > t0 else 0
    return f" A{f(a)} {f(b)} {f(math.degrees(tilt))} {large} {sweep} {P(*end)}"


# The short way round the limb between two points on it, clockwise or not
def limb_arc(cx, cy, r, start, end):
    a0, a1 = math.atan2(start[1] - cy, start[0] - cx), math.atan2(end[1] - cy, end[0] - cx)
    d = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
    return f" A{f(r)} {f(r)} 0 0 {1 if d > 0 else 0} {P(*end)}"


# Where a curve, given by its parameter, crosses a circle: scanned finely, then halved down
def crossings(curve, cx, cy, r, t0, t1, steps=4000):
    inside = lambda t: (curve(t)[0] - cx) ** 2 + (curve(t)[1] - cy) ** 2 - r * r
    found, prev = [], inside(t0)
    for i in range(1, steps + 1):
        t = t0 + (t1 - t0) * i / steps
        now = inside(t)
        if (prev < 0) != (now < 0):
            lo, hi = t - (t1 - t0) / steps, t
            for _ in range(60):
                mid = (lo + hi) / 2
                if (inside(mid) < 0) == (inside(lo) < 0):
                    lo = mid
                else:
                    hi = mid
            found.append((lo + hi) / 2)
        prev = now
    return found


def sample(curve, t0, t1, step):
    n = max(2, int(abs(t1 - t0) / step))
    return [curve(t0 + (t1 - t0) * i / n) for i in range(n + 1)]


# A crescent of shade on the far side of a ball: half the disc, less half an ellipse
def crescent(cx, cy, r, depth, side=-1):
    top, bottom = P(cx, cy - r), P(cx, cy + r)
    outer = 0 if side < 0 else 1
    return f"M{top} A{f(r)} {f(r)} 0 0 {outer} {bottom} A{f(r * depth)} {f(r)} 0 0 {1 - outer} {top} Z"


# A strip of the disc between two wavy edges, cut exactly at the limb
def disc_band(cx, cy, r, y0, y1, wave, phase):
    def edge(y):
        return lambda x: (x, y + wave * math.sin(x * 0.035 + phase))
    top, bottom = edge(y0), edge(y1)
    a = crossings(top, cx, cy, r, cx - r - 2, cx + r + 2)
    b = crossings(bottom, cx, cy, r, cx - r - 2, cx + r + 2)
    path = ""
    if len(a) == 2:
        pts = sample(top, a[0], a[1], 3)
        path = "M" + P(*pts[0]) + "".join(" L" + P(*q) for q in pts[1:])
        last = pts[-1]
    if len(b) == 2:
        pts = sample(bottom, b[1], b[0], 3)
        if path:
            path += limb_arc(cx, cy, r, last, pts[0])
        else:
            # Nothing above the strip but the limb: go over the top
            path = "M" + P(*pts[-1]) + f" A{f(r)} {f(r)} 0 {1 if y1 > cy else 0} 1 {P(*pts[0])}"
        path += "".join(" L" + P(*q) for q in pts[1:])
        path += limb_arc(cx, cy, r, pts[-1], top(a[0]) if len(a) == 2 else pts[-1]) if len(a) == 2 else ""
    else:
        # Nothing below but the limb: go round under the bottom
        path += f" A{f(r)} {f(r)} 0 {1 if y0 < cy else 0} 1 {P(*top(a[0]))}"
    return path + " Z"


# The part of an elliptic band (between two ellipses sharing a centre) that lies on a ball,
# along t from t0 to t1, cut exactly at the ball's limb
def band_on_ball(ex, ey, a0, b0, a1, b1, tilt, t0, t1, cx, cy, r):
    inner = lambda t: ellipse_at(ex, ey, a0, b0, tilt, t)
    outer = lambda t: ellipse_at(ex, ey, a1, b1, tilt, t)
    i0, i1 = crossings(inner, cx, cy, r, t0, t1)
    o0, o1 = crossings(outer, cx, cy, r, t0, t1)
    return ("M" + P(*outer(o0)) + ellipse_arc(a1, b1, tilt, o0, o1, outer(o1)) + limb_arc(cx, cy, r, outer(o1), inner(i1))
            + ellipse_arc(a0, b0, tilt, i1, i0, inner(i0)) + limb_arc(cx, cy, r, inner(i0), outer(o0)) + " Z")


# A whole elliptic band, two closed ellipses filled even-odd
def ring_band(ex, ey, a0, b0, a1, b1, tilt):
    def loop(a, b):
        s, m = ellipse_at(ex, ey, a, b, tilt, 0), ellipse_at(ex, ey, a, b, tilt, math.pi)
        return "M" + P(*s) + ellipse_arc(a, b, tilt, 0, math.pi, m) + ellipse_arc(a, b, tilt, math.pi, 2 * math.pi, s) + " Z"
    return loop(a1, b1) + " " + loop(a0, b0)


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

# Aster takes after Saturn: from one of its moons, the ringed giant never quite sets.
# The whole ring sits behind the globe; only the stretch of it that crosses the globe's
# face is drawn again in front, cut at the limb, so the two never meet in a seam.
rnd = random.Random(3)
R = 230
W2, H2 = 2 * 470, 2 * 240
cx, cy = W2 / 2, H2 / 2
tilt = -0.2
ring = [(1.42, 1.62, ["light", "skyLow", 0.35, 0.8]), (1.68, 2.0, ["light", "skyMid", 0.25, 0.7])]
back, front = [], []
for a0, a1, tone in ring:
    back.append(L(tone, ring_band(cx, cy, R * a0, R * a0 * 0.2, R * a1, R * a1 * 0.2, tilt), True))
    front.append(L(tone, band_on_ball(cx, cy, R * a0, R * a0 * 0.2, R * a1, R * a1 * 0.2, tilt, 0, math.pi, cx, cy, R)))
globe = [L(["skyLow", "light", 0.25], circle(cx, cy, R))]
tones = [["skyMid", "light", 0.35], ["skyLow", "light", 0.55], ["skyMid", "skyLow", 0.5], ["skyMid", "t0", 0.3], ["skyLow", "skyMid", 0.3]]
y = cy - R + 10
k = 0
while y < cy + R - 14:
    step = rnd.uniform(26, 58)
    globe.append(L(tones[k % len(tones)], disc_band(cx, cy, R, y, min(y + step * 0.6, cy + R - 10), rnd.uniform(2, 6), rnd.uniform(0, 6))))
    y += step
    k += 1
# The hexagon around its pole, seen almost edge-on
hexa = [(cx + 46 * math.cos(math.pi / 3 * i + 0.3), cy - R * 0.87 + 13 * math.sin(math.pi / 3 * i + 0.3)) for i in range(6)]
inner = [(cx + (x - cx) * 0.82, cy - R * 0.87 + (y - (cy - R * 0.87)) * 0.82) for x, y in hexa]
globe.append(L(["light", "white", 0.4, 0.55], poly(hexa) + " " + poly(inner[::-1]), True))
globe.append(L(["skyTop", "night", 0.2, 0.38], crescent(cx, cy, R, 0.5)))
globe.append(L(["skyTop", "night", 0.35, 0.45], crescent(cx, cy, R, 0.86)))
# The ring's shadow on the globe: the inner ring's band, lifted a little, cut at the limb
lift = 12
sx, sy = cx + lift * math.sin(tilt), cy - lift * math.cos(tilt)
globe.append(L(["skyTop", "night", 0.1, 0.3], band_on_ball(sx, sy, R * 1.42, R * 1.42 * 0.2, R * 1.62, R * 1.62 * 0.2, tilt, 0, math.pi, cx, cy, R)))
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
