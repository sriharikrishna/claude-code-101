#!/usr/bin/env python3
"""Tile per-page PNGs into a single numbered contact sheet.

Usage:
    contact_sheet.py --in DIR --out FILE [--cols N] [--title STR] [--tile-w PX]

Globs DIR for files ending in `-<number>.png` (the naming render.sh produces),
sorts them by that page number, and lays them out in a grid with page labels.
Exits 3 if Pillow is missing.
"""
import argparse
import glob
import os
import re
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.stderr.write(
        "contact_sheet.py: Pillow not found — needed to tile the contact sheet.\n"
        "Install it:  python3 -m pip install --user Pillow\n"
    )
    sys.exit(3)

PAGE_RE = re.compile(r"-(\d+)\.png$")


def load_font(size, bold=False):
    candidates = (
        ["/System/Library/Fonts/Supplemental/Arial Bold.ttf",
         "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]
        if bold else
        ["/System/Library/Fonts/Supplemental/Arial.ttf",
         "/System/Library/Fonts/Helvetica.ttc",
         "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]
    )
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="indir", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cols", type=int, default=5)
    ap.add_argument("--title", default="")
    ap.add_argument("--tile-w", type=int, default=380)
    args = ap.parse_args()

    files = [f for f in glob.glob(os.path.join(args.indir, "*.png")) if PAGE_RE.search(f)]
    files.sort(key=lambda f: int(PAGE_RE.search(f).group(1)))
    if not files:
        sys.stderr.write(f"contact_sheet.py: no page PNGs found in {args.indir}\n")
        sys.exit(1)

    cols = max(1, args.cols)
    tile_w = args.tile_w
    gap, label_h, margin = 14, 22, 28

    ar = (lambda im: im.height / im.width)(Image.open(files[0]))
    tile_h = round(tile_w * ar)
    rows = -(-len(files) // cols)

    W = margin * 2 + cols * tile_w + (cols - 1) * gap
    title_h = 54 if args.title else 8
    H = margin + title_h + rows * (tile_h + label_h) + (rows - 1) * gap + margin

    sheet = Image.new("RGB", (W, H), "#e9edf1")
    d = ImageDraw.Draw(sheet)
    if args.title:
        d.text((margin, margin + 6), args.title, fill="#00609c", font=load_font(26, True))
        d.text((margin, margin + 38),
               "Contact sheet · office-render (LibreOffice + poppler)",
               fill="#5b5b5b", font=load_font(14))

    y0 = margin + title_h
    fnum = load_font(13, True)
    for i, f in enumerate(files):
        r, c = divmod(i, cols)
        x = margin + c * (tile_w + gap)
        y = y0 + r * (tile_h + label_h + gap)
        im = Image.open(f).convert("RGB").resize((tile_w, tile_h), Image.LANCZOS)
        sheet.paste(im, (x, y))
        d.rectangle([x, y, x + tile_w - 1, y + tile_h - 1], outline="#c3ccd6", width=1)
        n = int(PAGE_RE.search(f).group(1))
        d.text((x + 2, y + tile_h + 4), str(n), fill="#00609c", font=fnum)

    sheet.save(args.out)
    print(args.out)


if __name__ == "__main__":
    main()
