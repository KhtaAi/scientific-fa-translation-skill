# scientific-fa-translation-skill

> ترجمهٔ **انگلیسی → فارسی علمی** با خروجی **PDF راست‌چین آمادهٔ چاپ** — یک مهارت (Skill) برای **Cline** و **Cursor** روی ویندوز.

این مخزن هم **خودِ مهارت** را دارد و هم یک **نصب‌کنندهٔ یک‌دستوری** که تمام اصلاح‌های لازم ویندوزی را انجام می‌دهد.
مهارت اصلی از [isArman/scientific-fa-translation-skill](https://github.com/isArman/scientific-fa-translation-skill) است (مجوز MIT)؛ اینجا بستهٔ نصب ویندوزی + رفع اشکال‌های آن اضافه شده.

---

## ⚡ نصب با یک دستور (ویندوز)

PowerShell را باز کنید و این را بچسبانید:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/KhtaAi/scientific-fa-translation-skill/main/bootstrap.ps1 | iex"
```

با گزینه‌ها (نصب برای Cursor هم، بدون تست):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/KhtaAi/scientific-fa-translation-skill/main/bootstrap.ps1))) -Cursor -SkipTests"
```

**Git Bash** (اگر ترجیح می‌دهید):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KhtaAi/scientific-fa-translation-skill/main/install.sh)
```

بعد از تمام شدن، **یک بار Cline را ری‌استارت کنید** و در چت بزنید:

```
/scientific-fa-translation-skill
```

---

## ✅ پیش‌نیازهایی که خودتان نصب می‌کنید

نصب‌کننده این چهار مورد را **نصب نمی‌کند** و اگر نباشند با پیام روشن متوقف می‌شود:

| پیش‌نیاز | توضیح |
| --- | --- |
| **Cline** | خودِ ابزار |
| **Git for Windows** | لازم است — اسکریپت‌های مهارت bash هستند و با Git Bash اجرا می‌شوند |
| **Python 3.9+** | از python.org، با تیک «Add python.exe to PATH» |
| **MS Edge یا Chrome** | موتور ساخت PDF (معمولاً از قبل هست) |
| *(اختیاری)* **MiKTeX + xepersian** | برای موتور اصلی XeLaTeX: کیفیت چاپ بهتر و متن قابل انتخاب |

## 🔧 و کارهایی که نصب‌کننده خودش انجام می‌دهد

۱. مهارت را در `%USERPROFILE%\.cline\skills\` نصب می‌کند (+ Cursor با `-Cursor`)
۲. `python3` را می‌سازد (ویندوز فقط `python.exe` دارد و `python3` به stub بی‌استفادهٔ Microsoft Store می‌رسد)
۳. `PYTHONUTF8=1` / `PYTHONIOENCODING=utf-8` / `BASH_ENV` را تنظیم می‌کند
۴. `%USERPROFILE%\bin` را به PATH کاربر اضافه می‌کند
۵. شیم `google-chrome` را می‌سازد (بدون آن، PDF به‌جای متن، **صفحهٔ خطای Edge** چاپ می‌شود)
۶. **poppler** را نصب می‌کند (`pdftotext`, `pdfinfo`, `pdftoppm`, `pdfimages`, `pdffonts`)
۷. `~/.bashenv` + `~/.bashrc` + `~/.bash_profile` را می‌سازد (اول `.bak` می‌گیرد)
۸. فونت **Vazirmatn** را نصب می‌کند
۹. `pillow` و `pymupdf` را نصب می‌کند
۱۰. در پایان `preflight.sh` و تست‌های رگرسیون را اجرا می‌کند

**admin لازم نیست · idempotent است (هر بار اجرا کنید بی‌خطر است) · اینترنت فقط برای مرحلهٔ ۹ لازم است.**
خروجی مورد انتظار پایان نصب: `25 ok، 1 fail، 3 skip` — آن یک fail یک محدودیت هارنس تست روی ویندوز است، نه نقص نصب.

---

## 🖱️ بدون یک‌دستوری: دابل‌کلیک

اگر ترجیح می‌دهید فایل‌ها دستتان باشد:

```powershell
git clone --depth 1 https://github.com/KhtaAi/scientific-fa-translation-skill.git "$env:USERPROFILE\Desktop\sfa-translation-kit"
```

بعد روی `INSTALL.cmd` در همان پوشه **دابل‌کلیک** کنید.

---

## 📖 استفاده

| کار | دستور |
| --- | --- |
| در چت Cline | `/scientific-fa-translation-skill` یا به فارسی: «این PDF را به فارسی علمی ترجمه کن و PDF راست‌چین بساز» |
| بررسی ماشین | `bash ~/.cline/skills/scientific-fa-translation-skill/scripts/preflight.sh` |
| چکر مکانیکی | `python3 .../scripts/check-fa.py doc.html --level system-docs --terms terms.tsv --manifest manifest.txt --strict` |
| ساخت PDF | `bash .../scripts/build-pdf.sh doc.html my-slug --verify` |
| تست‌ها | `bash .../tests/run.sh` |
| خروجی | `%USERPROFILE%\Documents\books\<slug>.pdf` + `<slug>.txt` |

⚠️ نمایشگر داخلی Chrome/Edge ممکن است متن فارسی را **معکوس** کپی کند (محدودیت موتور HTML).
از Adobe Reader / Firefox / Okta استفاده کنید، یا همان فایل `.txt` کنار PDF.

---

## 📁 ساختار مخزن

```text
bootstrap.ps1            ← یک‌دستوری: کیت را می‌آورد و نصب می‌کند
install-windows.ps1      نصب‌کنندهٔ واقعی (۱۱ مرحله)
INSTALL.cmd              ورودی دابل‌کلیکی برای ویندوز
install.sh               نصب یک‌دستوری لینوکس / macOS / WSL
WINDOWS-SETUP.md         یادداشت‌های فنی مفصل ویندوز (چرا هر اصلاح لازم بود)
skill\                   خودِ مهارت — SKILL.md, assets, references, scripts, tests
                         └─ README.upstream.md : راهنمای اصلی مخزن upstream
payload\
  bin\google-chrome      شیم مرورگر
  bash\.bashenv          ترجیح poppler واقعی بر pdftotext خراب Git
  bash\.bashrc, .bash_profile
  fonts\Vazirmatn-*.ttf
examples\a-little-princess\   مثال کارکردی کامل (فصل 1 و 2 «شاهزادهٔ کوچک»)
```

---

## 🧩 ساخت سند جدید

پوشهٔ `examples\a-little-princess` را کپی کنید و متن‌ها را عوض کنید. قواعد ساده است:

| نشانه در فایل `part-NN.txt` | خروجی |
| --- | --- |
| `# فصل 1 — عنوان` | سرتیتر فصل + ورود خودکار به «فهرست مطالب» |
| `@sign متن` | پاراگراف وسط‌چین (تابلو/پلاک) |
| `{{English}}` | `<span dir="ltr">` برای واژهٔ لاتین |
| ارقام لاتین خالی | خودکار isolate می‌شوند |

```bash
python3 build-doc.py     # part-*.txt  ->  doc.html
bash pipeline.sh         # ساخت + لینت --strict
bash build.sh            # لینت + build-pdf --verify
```

هر پاراگراف یک خط است؛ بین پاراگراف‌ها یک خط خالی. پوشهٔ `fonts\` باید کنار سند باشد
(از `payload\fonts` یا `skill\assets\fonts` کپی کنید).

---

## 🩺 رفع اشکال سریع

| نشانه | راه‌حل |
| --- | --- |
| اسلش‌کامند `/scientific-fa-translation-skill` نیست | Cline را کامل ببندید و باز کنید؛ `%USERPROFILE%\.cline\skills\scientific-fa-translation-skill\SKILL.md` باید باشد |
| `UnicodeEncodeError: 'charmap'` | پروسه را ری‌استارت کنید (یا دوباره نصب کنید) |
| `Python was not found` | نصب‌کننده را دوباره اجرا کنید؛ اگر خطای دسترسی داد فقط همان مرحله با admin |
| PDF = صفحهٔ خطای Edge | شیم `google-chrome` نصب نشده؛ نصب‌کننده را دوباره اجرا کنید |
| `.txt` کنار PDF خالی یا فقط لاتین | همان مشکل `pdftotext` خراب Git؛ `~/.bashenv` باید poppler را جلو بیندازد |
| `FAIL prepare-figures left mode=` | **طبیعی روی ویندوز** — محدودیت هارنس تست، نه نقص نصب |

جدول کامل + دستور حذف تغییرات: [`WINDOWS-SETUP.md`](WINDOWS-SETUP.md)

---

## 📜 مجوز

| | |
| --- | --- |
| مهارت | **MIT** — [skill/LICENSE](skill/LICENSE) — از [isArman/scientific-fa-translation-skill](https://github.com/isArman/scientific-fa-translation-skill) |
| Vazirmatn | **SIL OFL 1.1** |
| poppler | **GPL-2.0** — [poppler-windows](https://github.com/oschwartz10612/poppler-windows) |
| مثال «شاهزادهٔ کوچک» | متن اصلی ۱۹۰۵ **مالکیت عمومی** — [Project Gutenberg #146](https://www.gutenberg.org/ebooks/146) |

