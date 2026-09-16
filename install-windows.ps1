#Requires -Version 5.1
<#
  install-windows.ps1  —  scientific-fa-translation-skill, one-click installer

  همه‌چیز را از همین پوشه می‌خواند (اینترنت لازم نیست، جز برای pip اختیاری):
    skill\            کل مهارت (SKILL.md, assets, references, scripts, tests)
    payload\bin\      شیم google-chrome
    payload\bash\     .bashenv / .bashrc / .bash_profile
    payload\fonts\    Vazirmatn-Regular.ttf, Vazirmatn-Bold.ttf
    payload\poppler\  poppler-windows zip (pdftotext/pdfinfo/pdftoppm/pdfimages/pdffonts)

  اجرا:  دابل‌کلیک روی INSTALL.cmd   (یا همین اسکریپت با PowerShell)
  admin لازم نیست. idempotent است: اجرای دوباره چیزی را خراب نمی‌کند.

  گزینه‌ها:
    -SkipPoppler          نصب نکردن poppler
    -SkipPythonPackages   نصب نکردن pillow/pymupdf (به اینترنت نیاز دارد)
    -SkipTests            اجرا نکردن تست‌های رگرسیون در پایان
    -RepoUrl <git-url>    اگر پوشهٔ skill\ نبود، از این مخزن کلون کن
#>
[CmdletBinding()]
param(
  [switch]$SkipPoppler,
  [switch]$SkipPythonPackages,
  [switch]$SkipTests,
  [switch]$Cursor,
  [string]$RepoUrl = 'https://github.com/KhtaAi/scientific-fa-translation-skill.git',
  [string]$SkillName = 'scientific-fa-translation-skill'
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "   [ok]   $m" -ForegroundColor Green }
function Note($m) { Write-Host "   ...    $m" -ForegroundColor Gray }
function Warn($m) { Write-Host "   [warn] $m" -ForegroundColor Yellow }
function Fail($m) { Write-Host "   [FAIL] $m" -ForegroundColor Red; exit 1 }

# فایل‌های bash باید UTF-8 *بدون* BOM باشند: BOM شبانگ و اولین توکن را می‌شکند.
function Write-TextNoBom($path, $text) {
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}
function To-UnixPath($winPath) {
  '/' + $winPath.Substring(0, 1).ToLower() + ($winPath.Substring(2) -replace '\\', '/')
}
# اجرای دستور در Git Bash و گرفتن stdout+stderr به‌صورت متن (بدون کشتن اسکریپت
# توسط NativeCommandError؛ bash خودش به فایل می‌ریزد).
function Bash-Out($cmd) {
  $tmp = [System.IO.Path]::GetTempFileName()
  & $BashExe -lc "$cmd > '$(To-UnixPath $tmp)' 2>&1" | Out-Null
  $text = ''
  if (Test-Path $tmp) { $text = [System.IO.File]::ReadAllText($tmp, [System.Text.Encoding]::UTF8) }
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  return $text
}
# کپی درخت پوشه با robocopy (فایل‌های مخفی را هم می‌آورد)
function CopyTree($src, $dst) {
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  & robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { Fail "robocopy ناموفق: $src -> $dst (code $LASTEXITCODE)" }
  return $true
}

$KitRoot   = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$Payload   = Join-Path $KitRoot 'payload'
$SkillSrc  = Join-Path $KitRoot 'skill'
$HomeDir   = $env:USERPROFILE
$BinDir    = Join-Path $HomeDir 'bin'
$SkillsDir = Join-Path $HomeDir '.cline\skills'
$SkillPath = Join-Path $SkillsDir $SkillName
$BashEnv   = Join-Path $HomeDir '.bashenv'
$ToolsDir  = Join-Path $HomeDir 'tools'

Write-Host "scientific-fa-translation-skill — نصب روی ویندوز" -ForegroundColor White
Note "منبع بسته: $KitRoot"

# --------------------------------------------------------------------------
Step '۱. بررسی پیش‌نیازها'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  if (Test-Path (Join-Path $SkillSrc 'SKILL.md')) {
    Warn 'git نیست — مشکلی نیست، مهارت از همین بسته کپی می‌شود.'
  } else {
    Fail 'Git پیدا نشد. Git for Windows را نصب کنید: https://git-scm.com/download/win'
  }
} else {
  Ok "git $((& git --version 2>&1) -join '')"
}

$BashExe = 'C:\Program Files\Git\bin\bash.exe'
if (-not (Test-Path $BashExe)) {
  $cand = Get-ChildItem 'C:\Program Files*\Git\bin\bash.exe' -ErrorAction SilentlyContinue |
          Select-Object -First 1
  if (-not $cand) {
    Fail 'Git Bash پیدا نشد (C:\Program Files\Git\bin\bash.exe). Git for Windows لازم است — اسکریپت‌های مهارت bash هستند.'
  }
  $BashExe = $cand.FullName
}
Ok "Git Bash: $BashExe"

$pythonExe = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
  try { $pythonExe = (& py -3 -c "import sys; print(sys.executable)" 2>$null) } catch { }
}
if (-not $pythonExe -or -not (Test-Path $pythonExe)) {
  $cand = Get-Command python -ErrorAction SilentlyContinue
  if ($cand -and $cand.Source -notlike '*WindowsApps*') { $pythonExe = $cand.Source }
}
if (-not $pythonExe) {
  Fail 'Python 3 پیدا نشد. از https://www.python.org/downloads/windows/ نصب کنید و «Add python.exe to PATH» را فعال کنید.'
}
Ok "python: $pythonExe -- $((& $pythonExe --version 2>&1) -join '')"

$browser = $null
foreach ($c in @(
  (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
)) { if ($c -and (Test-Path $c)) { $browser = $c; break } }
if (-not $browser) { Fail 'نه MS Edge و نه Chrome پیدا نشد؛ یکی را نصب کنید (موتور ساخت PDF).' }
Ok "browser: $browser"

# --------------------------------------------------------------------------
Step '۲. نصب مهارت در ~/.cline/skills'
if (Test-Path (Join-Path $SkillSrc 'SKILL.md')) {
  Note "کپی از بستهٔ محلی: $SkillSrc"
  CopyTree $SkillSrc $SkillPath | Out-Null
  Remove-Item -Recurse -Force (Join-Path $SkillPath '.git') -ErrorAction SilentlyContinue
  Ok "نصب شد (آفلاین): $SkillPath"
} elseif (Test-Path (Join-Path $SkillPath 'SKILL.md')) {
  Note 'پوشهٔ skill در بسته نبود و مهارت از قبل نصب است -> git pull'
  if (Get-Command git -ErrorAction SilentlyContinue) {
    & git -C $SkillPath pull --ff-only 2>&1 | ForEach-Object { Note $_ }
  }
  Ok "به‌روزرسانی شد: $SkillPath"
} else {
  Warn 'پوشهٔ skill در بسته نبود -> کلون از اینترنت'
  New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
  & git clone --depth 1 $RepoUrl $SkillPath 2>&1 | ForEach-Object { Note $_ }
}
if (-not (Test-Path (Join-Path $SkillPath 'SKILL.md'))) { Fail 'SKILL.md پیدا نشد؛ نصب مهارت ناموفق بود.' }
Ok 'SKILL.md موجود است'

if ($Cursor) {
  $cursorSkills = Join-Path $HomeDir '.cursor\skills'
  $cursorPath = Join-Path $cursorSkills $SkillName
  New-Item -ItemType Directory -Force -Path $cursorSkills | Out-Null
  CopyTree $SkillPath $cursorPath | Out-Null
  Ok "همچنین برای Cursor نصب شد: $cursorPath"
}

# --------------------------------------------------------------------------
Step '۳. اطمینان از کارکرد دستور python3'
$probe = (Bash-Out 'python3 -c "pass"; echo $?') -join ''
if ("$probe".Trim() -match '0\s*$') {
  Ok 'python3 از قبل کار می‌کند'
} else {
  $pyDir = Split-Path $pythonExe -Parent
  Copy-Item $pythonExe (Join-Path $pyDir 'python3.exe') -Force
  $pyw = Join-Path $pyDir 'pythonw.exe'
  if (Test-Path $pyw) { Copy-Item $pyw (Join-Path $pyDir 'python3w.exe') -Force }
  $env:PATH = "$pyDir;$env:PATH"
  Ok "ساخته شد: $(Join-Path $pyDir 'python3.exe')"
  Note 'ویندوز فقط python.exe دارد و python3 به stub بی‌استفاده Microsoft Store می‌رسد.'
  Note "اگر خطای دسترسی گرفتید، این اسکریپت را با admin اجرا کنید (فقط همین مرحله)."
}

# --------------------------------------------------------------------------
Step '۴. متغیرهای محیطی سطح-کاربر'
$envWanted = [ordered]@{
  PYTHONUTF8       = '1'
  PYTHONIOENCODING = 'utf-8'
  BASH_ENV         = $BashEnv
}
foreach ($k in $envWanted.Keys) {
  if ([Environment]::GetEnvironmentVariable($k, 'User') -eq $envWanted[$k]) {
    Ok "$k از قبل تنظیم است"
  } else {
    [Environment]::SetEnvironmentVariable($k, $envWanted[$k], 'User')
    Ok "$k = $($envWanted[$k])"
  }
}
Note 'PYTHONUTF8: check-fa.py متن فارسی چاپ می‌کند و کدپیج cp1252 خطای UnicodeEncodeError می‌دهد.'

# --------------------------------------------------------------------------
Step '۵. افزودن %USERPROFILE%\bin به PATH کاربر'
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$parts = @($userPath -split ';' | Where-Object { $_ })
if ($parts -contains $BinDir) {
  Ok "$BinDir از قبل در PATH کاربر است"
} else {
  [Environment]::SetEnvironmentVariable('PATH', "$BinDir;$userPath", 'User')
  Ok "$BinDir به ابتدای PATH کاربر اضافه شد"
}

# --------------------------------------------------------------------------
Step '۶. شیم google-chrome (تا build-pdf.sh مرورگر را پیدا کند)'
# build-pdf.sh در find_chrome() فقط chromium/google-chrome/... را روی PATH
# می‌جوید که در ویندوز وجود ندارند؛ و آدرس file://$(realpath doc.html) در MSYS
# به file:///c/Users/... تبدیل می‌شود که کرومیوم نمی‌فهمد و صفحهٔ خطای
# ERR_FILE_NOT_FOUND را به‌عنوان PDF چاپ می‌کند. شیم هر دو را درست می‌کند.
$chromeSrc = Join-Path $Payload 'bin\google-chrome'
$chromeDst = Join-Path $BinDir 'google-chrome'
if (Test-Path $chromeSrc) {
  Copy-Item $chromeSrc $chromeDst -Force
  & $BashExe -c "chmod +x '$(To-UnixPath $chromeDst)'" 2>&1 | Out-Null
  Ok "نصب شد: $chromeDst"
} elseif (Test-Path $chromeDst) {
  Ok "شیم از قبل هست: $chromeDst"
} else {
  Fail "شیم در بسته پیدا نشد: $chromeSrc"
}

# --------------------------------------------------------------------------
Step '۷. poppler (pdftotext / pdfinfo / pdftoppm / pdfimages / pdffonts)'
# بدون آن: فایل کنارِ .txt ساخته نمی‌شود و --verify نمی‌تواند صفحات را raster کند.
$popplerCandidates = @(
  (Join-Path $HomeDir 'tools\poppler\bin'),
  (Join-Path $HomeDir 'tools\poppler\Library\bin'),
  (Join-Path $HomeDir 'scoop\apps\poppler\current\bin')
)
$popplerBin = $null
foreach ($c in $popplerCandidates) {
  if (Test-Path (Join-Path $c 'pdftotext.exe')) { $popplerBin = $c; break }
}
$popplerZip = Get-ChildItem (Join-Path $Payload 'poppler') -Filter '*.zip' -ErrorAction SilentlyContinue |
              Select-Object -First 1

if ($popplerBin) {
  Ok "poppler از قبل هست: $popplerBin"
} elseif ($SkipPoppler) {
  Warn 'poppler رد شد (-SkipPoppler)'
} elseif ($popplerZip) {
  Note "باز کردن بستهٔ آفلاین: $($popplerZip.Name)"
  $ex = Join-Path $env:TEMP 'sfa-poppler-expand'
  Remove-Item -Recurse -Force $ex -ErrorAction SilentlyContinue
  Expand-Archive -Path $popplerZip.FullName -DestinationPath $ex -Force
  $libBin = Get-ChildItem $ex -Recurse -Directory |
            Where-Object { $_.Name -eq 'bin' -and (Test-Path (Join-Path $_.FullName 'pdftotext.exe')) } |
            Select-Object -First 1
  if (-not $libBin) { Fail 'ساختار zip نامنتظره بود (bin با pdftotext.exe پیدا نشد).' }
  $dest = Join-Path $HomeDir 'tools\poppler\bin'
  New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
  Copy-Item $libBin.FullName $dest -Recurse -Force
  $popplerBin = $dest
  Remove-Item -Recurse -Force $ex -ErrorAction SilentlyContinue
  Ok "poppler نصب شد (آفلاین): $popplerBin"
} elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
  Note 'بستهٔ آفلاین نبود -> نصب با scoop'
  & scoop install poppler 2>&1 | ForEach-Object { Note $_ }
  if (Test-Path (Join-Path $popplerCandidates[2] 'pdftotext.exe')) { $popplerBin = $popplerCandidates[2] }
  Ok "poppler نصب شد: $popplerBin"
} else {
  Warn 'بستهٔ آفلاین نبود و scoop هم نیست -> تلاش برای دانلود از GitHub'
  try {
    $rel = Invoke-RestMethod 'https://api.github.com/repos/oschwartz10612/poppler-windows/releases/latest' `
      -Headers @{ 'User-Agent' = 'cline-installer' }
    $asset = $rel.assets | Where-Object { $_.name -like 'Release-*.zip' } | Select-Object -First 1
    if (-not $asset) { throw 'no Release-*.zip asset' }
    $tmpZip = Join-Path $env:TEMP $asset.name
    $ex = Join-Path $env:TEMP 'sfa-poppler-expand'
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmpZip -UseBasicParsing
    Remove-Item -Recurse -Force $ex -ErrorAction SilentlyContinue
    Expand-Archive -Path $tmpZip -DestinationPath $ex -Force
    $libBin = Get-ChildItem $ex -Recurse -Directory |
              Where-Object { $_.Name -eq 'bin' -and (Test-Path (Join-Path $_.FullName 'pdftotext.exe')) } |
              Select-Object -First 1
    if (-not $libBin) { throw 'bin directory not found in archive' }
    $dest = Join-Path $HomeDir 'tools\poppler\bin'
    New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
    Copy-Item $libBin.FullName $dest -Recurse -Force
    $popplerBin = $dest
    Ok "poppler نصب شد (دانلود): $popplerBin"
  } catch {
    Warn "نصب خودکار poppler ناموفق بود: $($_.Exception.Message)"
    Warn 'مهارت بدون آن هم کار می‌کند، ولی فایل .txt کنار PDF ساخته نمی‌شود.'
  }
}

# --------------------------------------------------------------------------
Step '۸. فایل‌های راه‌اندازی bash (~/.bashenv و ~/.bashrc و ~/.bash_profile)'
# ~/.bashenv پوشهٔ poppler را به ابتدای PATH می‌آورد. لازم است چون /etc/profile
# مسیر /mingw64/bin را اول می‌گذارد و در آنجا یک pdftotext.exe قدیمی و سرگردان
# هست که هیچ متن فارسی از PDFهای Chromium/Edge استخراج نمی‌کند (فایل .txt خالی
# می‌ماند و check-pdf-text-order همیشه inconclusive می‌دهد).
$bashProfile = Join-Path $HomeDir '.bash_profile'
$bashPairs = @(
  @{ Src = (Join-Path $Payload 'bash\.bashenv');      Dst = $BashEnv },
  @{ Src = (Join-Path $Payload 'bash\.bashrc');       Dst = (Join-Path $HomeDir '.bashrc') },
  @{ Src = (Join-Path $Payload 'bash\.bash_profile'); Dst = $bashProfile }
)
foreach ($pair in $bashPairs) {
  if (-not (Test-Path $pair.Src)) { Warn "در بسته نیست: $($pair.Src)"; continue }
  if (-not (Test-Path $pair.Dst)) {
    Copy-Item $pair.Src $pair.Dst -Force
    Ok "ساخته شد: $($pair.Dst)"
    continue
  }
  $a = [System.IO.File]::ReadAllText($pair.Dst, [System.Text.Encoding]::UTF8)
  $b = [System.IO.File]::ReadAllText($pair.Src, [System.Text.Encoding]::UTF8)
  if ($a -eq $b) { Ok "$($pair.Dst) از قبل درست است" }
  else {
    Copy-Item $pair.Dst "$($pair.Dst).bak" -Force
    Copy-Item $pair.Src $pair.Dst -Force
    Note "$($pair.Dst) متفاوت بود -> جایگزین شد (پشتیبان: .bak)"
  }
}

# --------------------------------------------------------------------------
Step '۹. فونت Vazirmatn'
$fontSrc = Join-Path $Payload 'fonts'
$fontDest = Join-Path $SkillPath 'assets\fonts'
New-Item -ItemType Directory -Force -Path $fontDest | Out-Null
$ttfs = @(Get-ChildItem $fontSrc -Filter '*.ttf' -ErrorAction SilentlyContinue)
if ($ttfs.Count -eq 0) {
  Warn "فونتی در بسته نیست: $fontSrc (با scripts/fetch-vazirmatn.sh تهیه کنید)"
} else {
  Copy-Item $ttfs.FullName $fontDest -Force
  Ok "$($ttfs.Count) فایل در $fontDest"
  # تلاش اختیاری: نصب در فونت‌های کاربر ویندوز (تا در مرورگر/برنامه‌ها هم باشد)
  $userFonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  $regKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  New-Item -ItemType Directory -Force -Path $userFonts | Out-Null
  foreach ($t in $ttfs) {
    $dstFont = Join-Path $userFonts $t.Name
    try {
      if (-not (Test-Path $dstFont)) { Copy-Item $t.FullName $dstFont -Force }
    } catch {
      Warn "کپی فونت ناموفق (بی‌خطر): $($t.Name)"
    }
    try {
      $name = "$($t.BaseName) (TrueType)"
      if (-not (Get-ItemProperty -Path $regKey -Name $name -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $regKey -Name $name -Value $dstFont `
          -PropertyType String -Force | Out-Null
      }
    } catch {
      Warn "ثبت رجیستری فونت ناموفق (بی‌خطر): $($t.BaseName)"
    }
  }
  Ok 'فونت برای کاربر ویندوز ثبت شد (اگر مرورگر هم ببیند بهتر است)'
}

# --------------------------------------------------------------------------
Step '۱۰. پکیج‌های پایتون (pillow, pymupdf) — نیازمند اینترنت'
if ($SkipPythonPackages) {
  Warn 'رد شد (-SkipPythonPackages)'
} else {
  & $pythonExe -m pip install --quiet --upgrade pillow pymupdf 2>&1 | ForEach-Object { Note $_ }
  $mods = (& $pythonExe -c "import PIL.Image, pymupdf; print(PIL.__version__)" 2>&1) -join ''
  if ($LASTEXITCODE -eq 0) { Ok "Pillow $mods و PyMuPDF نصب هستند" }
  else {
    Warn 'نصب/تأیید پکیج‌های پایتون موفق نبود (احتمالاً اینترنت نبود)'
    Note 'برای اسناد دارای تصویر لازم است:  python3 -m pip install pillow pymupdf'
    Note 'بدون آن هم لینت و ساخت PDF کار می‌کند.'
  }
}

# --------------------------------------------------------------------------
Step '۱۱. تأیید نصب'
$env:PATH             = "$BinDir;$env:PATH"
$env:BASH_ENV         = $BashEnv
$env:PYTHONUTF8       = '1'
$env:PYTHONIOENCODING = 'utf-8'
$skillUnix = To-UnixPath $SkillPath

Bash-Out "bash '$skillUnix/scripts/preflight.sh'" -split "`n" |
  ForEach-Object { Write-Host "   $_" }

$pdfTool = (Bash-Out 'command -v pdftotext').Trim()
$chrome  = (Bash-Out 'command -v google-chrome').Trim()
$pyTool  = (Bash-Out 'command -v python3').Trim()
foreach ($p in @(
  @{ Name = 'pdftotext';     Value = $pdfTool },
  @{ Name = 'google-chrome'; Value = $chrome },
  @{ Name = 'python3';       Value = $pyTool }
)) {
  if (-not $p.Value) { Warn "$($p.Name): پیدا نشد" }
  elseif ($p.Value -like '*mingw64*') { Warn "$($p.Name): $($p.Value)  <-- نسخهٔ خراب Git" }
  else { Ok "$($p.Name): $($p.Value)" }
}
if ($pdfTool -like '*mingw64*') {
  Warn 'pdftotext به نسخهٔ خراب Git می‌رسد؛ راه‌حل قطعی: با دسترسی admin فایل'
  Warn '  C:\Program Files\Git\mingw64\bin\pdftotext.exe  را پاک یا تغییرنام دهید.'
}

if (-not $SkipTests) {
  Write-Host ''
  Note 'اجرای tests/run.sh ...'
  $testOut = Bash-Out "bash '$skillUnix/tests/run.sh'"
  $summary = @{ ok = 0; FAIL = 0; skip = 0 }
  $testOut -split "`n" | ForEach-Object {
    if ($_ -match '^(ok|FAIL|skip)\s') { $summary[$Matches[1]]++ }
  }
  Note "خلاصه: $($summary['ok']) ok، $($summary['FAIL']) fail، $($summary['skip']) skip"
  Note 'روی ویندوز یک FAIL طبیعی است: «prepare-figures left mode=» — جزئیات در README.'
}

# --------------------------------------------------------------------------
Step 'پایان'
Write-Host "   مهارت نصب شد: $SkillPath"
Write-Host ''
Write-Host '   ۱) یک بار Cline را ری‌استارت کنید' -ForegroundColor Yellow
Write-Host '      (متغیرهای محیطی سطح-کاربر فقط به پروسه‌های جدید ارث می‌رسند)'
Write-Host '   ۲) در چت Cline بزنید:  /scientific-fa-translation-skill'
Write-Host '      یا به فارسی: «این PDF را به فارسی علمی ترجمه کن و PDF راست‌چین بساز»'
Write-Host ''
Write-Host "   مثال کارکردی + قالب آماده:  $KitRoot\examples\a-little-princess" -ForegroundColor White
Write-Host "   خروجی PDF در:              $HomeDir\Documents\books\" -ForegroundColor White
Write-Host ''
Write-Host '   نصب روی یک سیستم دیگر، با یک دستور:' -ForegroundColor White
Write-Host '     powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/KhtaAi/scientific-fa-translation-skill/main/bootstrap.ps1 | iex"' -ForegroundColor Gray



