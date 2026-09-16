import glob
import os
import pathlib
import re
import sys
import pymupdf
from PIL import Image, ImageStat

W = pathlib.Path(__file__).resolve().parent
SLUG = os.environ.get("SLUG", "shahzade-kuchak-fasl-1-2")
PDF = (pathlib.Path(sys.argv[1]) if len(sys.argv) > 1
       else pathlib.Path.home() / "Documents" / "books" / f"{SLUG}.pdf")

print("=== per-page ink coverage (blank page would be ~0%) ===")
doc = pymupdf.open(PDF)
for i, page in enumerate(doc):
    pix = page.get_pixmap(dpi=72)
    s = pix.samples
    nw = sum(1 for j in range(0, len(s), pix.n) if s[j] < 200)
    cov = 100.0 * nw / (pix.width * pix.height)
    print(f"  page {i+1:>2}: ink {cov:5.2f}%")

print("\n=== raster samples written by --verify ===")
for p in sorted(glob.glob(os.path.join(W, "verify-*.png"))):
    im = Image.open(p).convert("L")
    st = ImageStat.Stat(im)
    dark = sum(1 for v in im.getdata() if v < 200)
    print(f"  {os.path.basename(p)}: {im.size} mean={st.mean[0]:.1f} "
          f"dark_px={dark} ({100.0*dark/(im.size[0]*im.size[1]):.2f}%)")

print("\n=== logical-order text present (from the skim of page 1) ===")
t = doc[0].get_text()
print("first 200 chars:", re.sub(r"\s+", " ", t)[:200])
