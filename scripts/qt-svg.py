#!/usr/bin/env python3
# Make a traced SVG (VectorCraft's Image Trace) draw right in Quickshell.
#
#   qt-svg.py traced.svg source.png out.svg [gamma]
#
# - gamma: undo the brightening done before tracing (magick in.png -channel RGB -gamma 2.4),
#   so dark hair keeps its strands. Leave it out if the image wasn't brightened.
# - Qt gives up on paths with too many points. A traced colour's biggest path is mostly
#   holes that other colours fill anyway, so only the holes that are really empty in
#   source.png stay, and that path is drawn first.
# - A hairline stroke of each shape's own colour closes the seams between shapes.
import re
import sys

from PIL import Image

LIMIT = 100000
src, png, dst = sys.argv[1:4]
gamma = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
text = open(src).read()
alpha = Image.open(png).getchannel("A").load()
size = Image.open(png).size


def darker(m):
    rgb = [int(m.group(1)[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return "#" + "".join(f"{round(255 * c ** gamma):02x}" for c in rgb)


def polygon(sub):
    pts = []
    for cmd, args in re.findall(r"([MLCZ])([^MLCZ]*)", sub):
        vals = list(map(float, re.findall(r"-?\d+(?:\.\d+)?", args)))
        step = 6 if cmd == "C" else 2
        pts += [(vals[j + step - 2], vals[j + step - 1]) for j in range(0, len(vals), step)]
    return pts


def area(pts):
    return sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1])) / 2


def inside(x, y, pts):
    hit = False
    for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]):
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            hit = not hit
    return hit


def empty(pts):
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    seen = clear = 0
    for y in range(int(min(ys)), int(max(ys)) + 1, 2):
        for x in range(int(min(xs)), int(max(xs)) + 1, 2):
            if 0 <= x < size[0] and 0 <= y < size[1] and inside(x + 0.5, y + 0.5, pts):
                seen += 1
                clear += alpha[x, y] < 64
    return seen and clear / seen > 0.5


first = []


def trim(m):
    d = m.group(2)
    if len(d) <= LIMIT:
        return m.group(0)
    info = [(s, polygon(s)) for s in re.split(r"(?=M)", d) if s.strip()]
    sign = 1 if area(max(info, key=lambda t: abs(area(t[1])))[1]) > 0 else -1
    keep = [s.strip() for s, p in info if area(p) * sign > 0 or empty(p)]
    first.append(f'<path d="{" ".join(keep)}"{m.group(1)}{m.group(3)}/>')
    return ""


text = re.sub(r"#([0-9a-fA-F]{6})\b", darker, text)
text = re.sub(r"(\d+\.\d)\d+", r"\1", text)
text = re.sub(r'<path((?:(?! d=)[^>])*) d="([^"]*)"([^>]*)/>', trim, text)
at = text.index("<path")
text = text[:at] + "".join(first) + text[at:]
text = re.sub(r'fill="(#[0-9a-f]{6})"', r'fill="\1" stroke="\1" stroke-width="1.2" stroke-linejoin="round"', text)
open(dst, "w").write(text)
