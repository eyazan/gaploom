#!/usr/bin/env python3
"""Renders the app icon (same design as assets/icon.svg) to PNG sizes for PWA / iOS."""
from PIL import Image, ImageDraw
import os, sys

def icon(size, rounded=True):
    s = size / 256.0
    ss = 4  # supersample
    W = size * ss
    k = s * ss
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bg = (0x1b, 0x1f, 0x33, 255)
    if rounded:
        d.rounded_rectangle([0, 0, W - 1, W - 1], radius=int(56 * k), fill=bg)
    else:
        d.rectangle([0, 0, W, W], fill=bg)
    d.rounded_rectangle([40 * k, 60 * k, 216 * k, 196 * k], radius=int(26 * k), fill=(0xe8, 0xa5, 0x98, 255))
    d.rounded_rectangle([98 * k, 98 * k, 158 * k, 158 * k], radius=int(14 * k), fill=(0x16, 0x1a, 0x2c, 255))
    d.rectangle([0, 120 * k, 98 * k, 136 * k], fill=(0xff, 0xd2, 0x7a, 230))
    r = 22 * k
    d.ellipse([128 * k - r, 128 * k - r, 128 * k + r, 128 * k + r], outline=(0xff, 0xd2, 0x7a, 255), width=int(7 * k))
    r = 5 * k
    d.ellipse([128 * k - r, 128 * k - r, 128 * k + r, 128 * k + r], fill=(0xff, 0xf6, 0xdc, 255))
    return im.resize((size, size), Image.LANCZOS)

out = sys.argv[1] if len(sys.argv) > 1 else "assets/icons"
os.makedirs(out, exist_ok=True)
for n in (144, 180, 512):
    icon(n).save(os.path.join(out, f"icon_{n}.png"))
# iOS requires a square, opaque 1024 icon without transparency.
icon(1024, rounded=False).convert("RGB").save(os.path.join(out, "icon_1024.png"))
print("ok")
