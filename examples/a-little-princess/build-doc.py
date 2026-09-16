"""Build doc.html from the translation parts, reusing the skill's HTML template.

Markup in the part files:
  # heading        -> <h2 id="ch-N">, and a TOC entry
  @sign text       -> centred sign/plate paragraph
  {{text}}         -> LTR isolate (kept English/French runs)
  blank-line breaks paragraphs
Standalone ASCII digit runs in Persian text are isolated automatically.
"""
import html
import pathlib
import re

# self-locating so the folder works on any machine
SK = pathlib.Path.home() / ".cline" / "skills" / "scientific-fa-translation-skill"
W = pathlib.Path(__file__).resolve().parent

tpl = (SK / "assets" / "rtl-document.html").read_text(encoding="utf-8")
head = tpl[: tpl.index("</head>") + len("</head>")]
head = head.replace("<title>TITLE</title>", "<title>شاهزادهٔ کوچک — فصل 1 و 2</title>")
head = head.replace(
    "</head>",
    "  <style>\n"
    "    h1 { text-align: center; }\n"
    "    p.subtitle { text-align: center; font-size: 1.05em; margin-top: 0;\n"
    "                 margin-bottom: 2rem; }\n"
    "    p.sign { text-align: center; font-weight: 700; margin: 0.1em 0; }\n"
    "  </style>\n"
    "</head>",
)


def esc_inline(s: str) -> str:
    out = []
    for i, seg in enumerate(re.split(r"\{\{(.+?)\}\}", s)):
        if i % 2 == 1:                        # inside {{ }} -> LTR isolate
            out.append(f'<span dir="ltr">{html.escape(seg, quote=False)}</span>')
        else:
            e = html.escape(seg, quote=False)
            e = re.sub(r"(?<![0-9A-Za-z])([0-9]+(?:\.[0-9]+)?)(?![0-9A-Za-z])",
                       r'<span dir="ltr">\1</span>', e)
            out.append(e)
    return "".join(out)


lines: list[str] = []
for part in sorted(W.glob("part-*.txt")):
    lines.extend(part.read_text(encoding="utf-8").split("\n"))

blocks: list[tuple[str, str]] = []
buf: list[str] = []


def flush() -> None:
    if buf:
        blocks.append(("p", " ".join(buf)))
        buf.clear()


for raw in lines:
    line = raw.strip()
    if not line:
        flush()
    elif line.startswith("# "):
        flush()
        blocks.append(("h2", line[2:].strip()))
    elif line.startswith("@sign "):
        flush()
        blocks.append(("sign", line[6:].strip()))
    else:
        buf.append(line)
flush()

body, toc = [], []
for kind, text in blocks:
    if kind == "h2":
        anchor = f"ch-{len(toc) + 1}"
        rendered = esc_inline(text)
        toc.append((anchor, rendered))
        body.append(f'  <h2 id="{anchor}">{rendered}</h2>')
    elif kind == "sign":
        body.append(f'  <p class="sign">{esc_inline(text)}</p>')
    else:
        body.append(f"  <p>{esc_inline(text)}</p>")

toc_html = ['  <nav class="toc">', "    <h2>فهرست مطالب</h2>", "    <ol>"]
for anchor, title in toc:
    toc_html.append(f'      <li><a class="toc-leaf" href="#{anchor}">{title}</a></li>')
toc_html += ["    </ol>", "  </nav>", ""]

refs = [
    '  <section class="refs" dir="ltr">',
    "    <h2>منابع</h2>",
    "    <ol>",
    "      <li>Burnett, Frances Hodgson. <i>A Little Princess</i>. 1905. "
    "Project Gutenberg eBook #146 (release 1994-07-01, updated 2024-10-29). "
    '<a href="https://www.gutenberg.org/ebooks/146">'
    "https://www.gutenberg.org/ebooks/146</a></li>",
    "    </ol>",
    "  </section>",
    "",
]

colophon = [
    '  <section class="colophon">',
    "    <h2>یادداشت نشر</h2>",
    "    <p>" + esc_inline(
        "این متن ترجمهٔ فارسی رمان {{A Little Princess}} اثر فرانسس هاجسون "
        "برنت است — فصل 1 به‌طور کامل و آغاز فصل 2."
    ) + "</p>",
    "    <p>" + esc_inline(
        "منبع: {{https://www.gutenberg.org/ebooks/146}} — "
        "مجوز: {{Public Domain}} — تاریخ دریافت: {{2026-09-16}}."
    ) + "</p>",
    "    <p>" + esc_inline(
        "نام‌های خاص به فارسی آوانگاری شده‌اند و واژه‌های فرانسوی در یک بلوک "
        "جداگانهٔ چپ‌به‌راست نگه داشته شده‌اند. ترجمه با "
        "{{scientific-fa-translation-skill}} انجام شده است."
    ) + "</p>",
    "  </section>",
]

doc = "\n".join(
    [head, "<body>",
     '  <h1>شاهزادهٔ کوچک</h1>',
     '  <p class="subtitle">' + esc_inline("ترجمهٔ فصل 1 و آغاز فصل 2") + "</p>",
     ""] + toc_html + body + [""] + refs + colophon + ["</body>", "</html>", ""]
)

(W / "doc.html").write_text(doc, encoding="utf-8")
print("blocks:", len(blocks), "| paragraphs:", sum(1 for k, _ in blocks if k == "p"))
print("chapters:", len(toc), "->", [t for _, t in toc])
print("doc.html chars:", len(doc))
