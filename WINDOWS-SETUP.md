# اجرای این مهارت روی ویندوز — یادداشت محلی

> این فایل بخشی از مخزن upstream نیست؛ یک یادداشت نصب محلی است که با `git pull`
> دست‌نخورده می‌ماند (untracked).

## وضعیت نصب

| مورد | مقدار |
| --- | --- |
| محل مهارت | `C:\Users\Kh.Ta\.cline\skills\scientific-fa-translation-skill` |
| مخزن | `https://github.com/isArman/scientific-fa-translation-skill` (commit `27cad0f`) |
| موتور PDF فعال | **MS Edge headless** (مسیر HTML) — XeLaTeX نصب نیست |
| پایتون | 3.14.6 در `%LOCALAPPDATA%\Programs\Python\Python314` |
| فونت | Vazirmatn (از قبل در ویندوز نصب بود و در PDF جاسازی می‌شود) |
| خروجی | `C:\Users\Kh.Ta\Documents\books\<slug>.pdf` + `<slug>.txt` |

تست رگرسیون: `bash tests/run.sh` → همه پاس، به‌جز **یک** مورد که محدودیت هارنس
تست روی ویندوز است (پایین توضیح داده شده).

## نصب روی یک سیستم دیگر — ویندوز

اسکریپت `install-windows.ps1` در همین پوشه همه‌ی کارها را خودکار انجام می‌دهد.
admin لازم نیست، idempotent است و اجرای دوباره‌اش بی‌خطر است.

```powershell
# ۱) مهارت را در محل اسکیل‌های Cline کلون کنید
git clone --depth 1 https://github.com/isArman/scientific-fa-translation-skill.git `
  "$env:USERPROFILE\.cline\skills\scientific-fa-translation-skill"

# ۲) نصب‌کننده را اجرا کنید
powershell -NoProfile -ExecutionPolicy Bypass -File `
  "$env:USERPROFILE\.cline\skills\scientific-fa-translation-skill\install-windows.ps1"
```

گزینه‌ها:

| گزینه | کار |
| --- | --- |
| `-RepoUrl <git-url>` | استفاده از فورک خودتان به‌جای مخزن اصلی |
| `-SkipPoppler` | نصب نکردن poppler |
| `-SkipPythonPackages` | نصب نکردن pillow/pymupdf |
| `-SkipTests` | اجرا نکردن تست‌های رگرسیون در پایان |

اسکریپت این ۱۰ مرحله را انجام می‌دهد: بررسی پیش‌نیازها → کلون `git pull` →
ساخت `python3.exe` → تنظیم `PYTHONUTF8`/`PYTHONIOENCODING`/`BASH_ENV` →
افزودن `%USERPROFILE%\bin` به PATH → نوشتن شیم `google-chrome` →
نصب poppler → نوشتن `~/.bashenv` و `~/.bashrc` و `~/.bash_profile` →
نصب pillow/pymupdf → اجرای `preflight.sh` و `tests/run.sh`.

پیش‌نیازهایی که باید روی سیستم جدید باشند:

| پیش‌نیاز | چرا |
| --- | --- |
| Cline | بارگذاری `SKILL.md` از `~/.cline/skills` |
| **Git for Windows** | همه‌ی اسکریپت‌های مهارت bash هستند (Git Bash) |
| **Python 3.9+** | `check-fa.py` و اسکریپت‌های تصویر؛ نصب‌کننده `python3.exe` را می‌سازد |
| **MS Edge یا Chrome** | موتور ساخت PDF (مسیر HTML) |
| (اختیاری) **MiKTeX + xepersian** | موتور اصلی XeLaTeX؛ کیفیت چاپ و متن قابل انتخاب بهتر |

خروجی مورد انتظار پایان کار: `25 ok، 1 fail، 3 skip`
(آن یک fail، همان محدودیت هارنس تست ویندوز است که پایین توضیح داده شده).

## سیستم‌های لینوکس / macOS

این مخزن برای همین سیستم‌ها نوشته شده و هیچ اصلاحی لازم ندارد:

```bash
mkdir -p ~/.cline/skills && cd ~/.cline/skills
git clone https://github.com/isArman/scientific-fa-translation-skill.git

sudo apt install texlive-xetex texlive-lang-arabic \
                 texlive-fonts-recommended latexmk poppler-utils
python3 -m pip install pillow pymupdf

bash scientific-fa-translation-skill/scripts/preflight.sh
bash scientific-fa-translation-skill/tests/run.sh
```

برای **Cursor** همان کار، فقط با مسیر `~/.cursor/skills` به‌جای `~/.cline/skills`.

## چهار اصلاح لازم برای ویندوز

### ۱. `python3` وجود نداشت
ویندوز فقط `python.exe` دارد و `python3` به stub تقلبی Microsoft Store می‌رسید
(«Python was not found») و باعث شکست همه‌ی چک‌ها می‌شد.

```powershell
Copy-Item "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe" `
          "$env:LOCALAPPDATA\Programs\Python\Python314\python3.exe"
```

### ۲. انکودینگ کنسول (`UnicodeEncodeError: 'charmap' codec`)
`check-fa.py` متن فارسی چاپ می‌کند و کدپیج پیش‌فرض ویندوز (cp1252) خطا می‌داد.
دو متغیر محیطی سطح-کاربر تنظیم شد:

```
PYTHONUTF8       = 1
PYTHONIOENCODING = utf-8
```

### ۳. پیدا نشدن مرورگر برای مسیر HTML
`scripts/build-pdf.sh` در تابع `find_chrome()` فقط نام‌های لینوکسی
(`chromium`, `google-chrome`, …) را روی `PATH` می‌جوید که در ویندوز وجود ندارند.
بدتر: اسکریپت آدرس `file://$(realpath doc.html)` می‌سازد که در MSYS به شکل
`file:///c/Users/...` درمی‌آید و کرومیوم آن را نمی‌فهمد → صفحه‌ی خطای
`ERR_FILE_NOT_FOUND` **به‌عنوان PDF چاپ می‌شود** و شبیه یک build موفق به نظر می‌رسد.

راه‌حل: یک شیم در `C:\Users\Kh.Ta\bin\google-chrome` که Edge را پیدا می‌کند و
آدرس‌های `file://` را با `cygpath` به شکل درست ویندوزی (`file:///C:/...`) تبدیل
می‌کند. پوشه `%USERPROFILE%\bin` به ابتدای `PATH` کاربر اضافه شد.

### ۴. `pdftotext` قدیمی و خراب در Git
در `C:\Program Files\Git\mingw64\bin\pdftotext.exe` یک نسخه‌ی سرگردان و قدیمی
(Aug 2025) وجود دارد که Git آن را ارائه نمی‌کند. این فایل **هیچ متنی** از
PDFهای تولیدشده توسط Chromium/Edge استخراج نمی‌کند (فونت CID جاسازی‌شده)، و
بی‌سروصدا این‌ها را خراب می‌کرد:

- `scripts/check-pdf-text-order.py` همیشه `inconclusive` می‌داد
- فایل کنارِ `.txt` بدون هیچ متن فارسی تولید می‌شد

چون `/etc/profile` مسیر `/mingw64/bin` را اول می‌گذارد، افزودن مسیر به `PATH`
ویندوز کافی نبود. poppler واقعی (نسخه ۲۶.۰۹ از scoop) در
`C:\Users\Kh.Ta\.bashenv` به ابتدای `PATH` اضافه شد، و برای اینکه
`bash script.sh` (shell غیرتعاملی) هم آن را بخواند، متغیر محیطی سطح-کاربر:

```
BASH_ENV = C:\Users\Kh.Ta\.bashenv
```

فایل‌های ساخته‌شده: `~/.bashenv` (منطق)، `~/.bashrc` (آن را source می‌کند)،
و `~/.bash_profile` که خود Git Bash ساخته است.

```powershell
python3 -m pip install pillow pymupdf   # fig flatten / crop
scoop install poppler                   # pdftotext, pdfinfo, pdftoppm, pdfimages, pdffonts
```

## نحوه استفاده

### در چت Cline
با اسلش‌کامند یا در متن درخواست:

```
/scientific-fa-translation-skill
```

یا به فارسی: «این مقاله را به فارسی علمی ترجمه کن و PDF راست‌چین بساز».
Cline فایل `SKILL.md` را خودکار (بر اساس `description`) بارگذاری می‌کند.

### اجرای دستی خط فرمان (Git Bash)

```bash
SK=/c/Users/Kh.Ta/.cline/skills/scientific-fa-translation-skill

bash "$SK/scripts/preflight.sh"                    # چه چیزی روی این ماشین ساخته می‌شود
python3 "$SK/scripts/check-fa.py" doc.tex \
  --level system-docs --terms terms.tsv \
  --manifest manifest.txt --strict                 # چکر مکانیکی

bash "$SK/scripts/build-pdf.sh" doc.tex my-slug --verify
bash "$SK/tests/run.sh"
```

`build-pdf.sh` پیش از هر build با `check-fa.py --strict` lint می‌کند و اگر lint،
بررسی تصاویر، کامپایل یا `--verify` شکست بخورد، PDF را به `Documents/books` کپی
نمی‌کند. کنار سند به `terms.tsv` و `manifest.txt` نیاز دارد.

## نکات و محدودیت‌های باقی‌مانده

- **بعد از این تغییرات Cline را یک بار ری‌استارت کنید.** متغیرهای محیطی سطح-کاربر
  (`PYTHONUTF8`, `BASH_ENV`, `PATH`) برای پروسه‌هایی که بعد از تغییر شروع شوند
  اعمال می‌شوند؛ پروسه‌ی در حال اجرای Cline هنوز محیط قدیمی را به فرزندانش می‌دهد.
- **XeLaTeX نصب نیست**، پس موتور فعلی مسیر HTML/Edge است: نمایش راست‌چین درست است
  اما ترتیب متن در استریم PDF «بصری» است. کپی‌کردن متن در نمایشگر داخلی Chrome/Edge
  ممکن است معکوس شود — از Adobe Reader، Firefox، یا از فایل کنارِ `.txt` استفاده کنید
  (همان که `build-pdf.sh` می‌سازد). برای بهترین کیفیت چاپ، MiKTeX + بسته‌ی
  `xepersian` را نصب کنید؛ پس از آن `build-pdf.sh` خودکار به مسیر `.tex` می‌رود.
- **یک تست همیشه fail می‌شود** (روی ویندوز، بی‌ربط به عملکرد):
  `FAIL prepare-figures left mode=` در `tests/run.sh:239` مسیری MSYS
  (`/c/Users/...`) را *داخل رشته‌ی کد* به پایتون ویندوزی می‌دهد
  (`python3 -c "Image.open('/c/...')"`) و پایتون ویندوز چنین مسیری را باز نمی‌کند.
  تبدیل مسیر MSYS فقط برای آرگومان‌های جداگانه انجام می‌شود، نه برای متنی که داخل
  `-c` است. خود تابع درست کار می‌کند: `ok prepare-figures --check reports alpha` پاس است.
- `preflight.sh` هشدار «no fa-capable face» می‌دهد چون `fc-list` (fontconfig) روی
  ویندوز نیست؛ این هشدار بی‌ربط است — Vazirmatn نصب است و در PDF جاسازی می‌شود
  (خروجی `pdffonts` آن را تأیید می‌کند).
- پیام خطای `EDGE_IDENTITY ... kImplicitSignInFailure` در لاگ بی‌خطر است.

## برگرداندن تغییرات

```powershell
Remove-Item -Recurse "$env:USERPROFILE\.cline\skills\scientific-fa-translation-skill"
Remove-Item "$env:USERPROFILE\bin\google-chrome"
Remove-Item "$env:USERPROFILE\.bashenv", "$env:USERPROFILE\.bashrc", "$env:USERPROFILE\.bash_profile"
Remove-Item "$env:LOCALAPPDATA\Programs\Python\Python314\python3.exe"
[Environment]::SetEnvironmentVariable('PYTHONUTF8',       $null, 'User')
[Environment]::SetEnvironmentVariable('PYTHONIOENCODING', $null, 'User')
[Environment]::SetEnvironmentVariable('BASH_ENV',         $null, 'User')
# و در صورت تمایل: scoop uninstall poppler ; python3 -m pip uninstall pillow pymupdf
```

### پیش‌نیازهای اضافه نصب‌شده

```powershell
python3 -m pip install pillow pymupdf   # fig flatten / crop
scoop install poppler                   # pdftotext, pdfinfo, pdftoppm, pdfimages, pdffonts
```
