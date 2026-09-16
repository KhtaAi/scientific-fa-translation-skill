import pathlib
import re

W = pathlib.Path(__file__).resolve().parent
src = (W / "source-span.txt").read_text(encoding="utf-8")
en_words = len(src.split())

fa = " ".join((W / f"part-{i:02d}.txt").read_text(encoding="utf-8")
              for i in range(1, 6))
fa_words = len(fa.split())
fa_chars = len(fa)

latin_runs = re.findall(r"[A-Za-z][A-Za-z'\- ]{2,}", fa)
print(f"English source words : {en_words}")
print(f"Persian words        : {fa_words}")
print(f"Persian characters   : {fa_chars}")
print(f"ratio (fa/en words)  : {fa_words/en_words:.2f}")
print()
print("Latin runs left in the Persian text (all should be intentional):")
for r in sorted(set(latin_runs)):
    print("   ", repr(r.strip()))

sp = (W / "doc.html").read_text(encoding="utf-8")
print()
print("doc.html LTR isolates:", sp.count('dir="ltr"'))
print("doc.html paragraphs  :", sp.count("<p"))
print("doc.html h2 headings :", sp.count("<h2"))
