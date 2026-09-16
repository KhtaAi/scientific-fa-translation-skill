# bootstrap.ps1 — نصب یک‌دستوری scientific-fa-translation-skill روی Cline (ویندوز)
#
# اجرا:
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/KhtaAi/scientific-fa-translation-skill/main/bootstrap.ps1 | iex"
#
# گزینه‌ها (چون این اسکریپت با iex اجرا می‌شود، param() نمی‌تواند داشته باشد
# و گزینه‌ها از متغیر محیطی خوانده می‌شوند):
#   $env:SFA_CURSOR=1        همچنین در ~/.cursor/skills نصب کن
#   $env:SFA_SKIP_TESTS=1    تست‌های رگرسیون را اجرا نکن
#   $env:SFA_SKIP_POPPLER=1  poppler را نصب نکن
#   $env:SFA_REPO=owner/repo فورک دیگر (پیش‌فرض KhtaAi/scientific-fa-translation-skill)
#   $env:SFA_BRANCH=main     شاخهٔ دیگر
#   $env:SFA_KIT_DIR=C:\path استفاده از یک کیت محلی به‌جای دانلود
#
# نمونه با گزینه:
#   $env:SFA_CURSOR=1; $env:SFA_SKIP_TESTS=1; irm https://raw.githubusercontent.com/KhtaAi/scientific-fa-translation-skill/main/bootstrap.ps1 | iex
#
# این اسکریپت فقط کیت را می‌آورد؛ کار اصلی را install-windows.ps1 انجام می‌دهد.

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Test-True($v) { return ($v -eq '1' -or $v -eq 'true' -or $v -eq 'yes') }

$Cursor      = Test-True $env:SFA_CURSOR
$SkipTests   = Test-True $env:SFA_SKIP_TESTS
$SkipPoppler = Test-True $env:SFA_SKIP_POPPLER

$Repo   = if ($env:SFA_REPO)   { $env:SFA_REPO }   else { 'KhtaAi/scientific-fa-translation-skill' }
$Branch = if ($env:SFA_BRANCH) { $env:SFA_BRANCH } else { 'main' }
$Work   = if ($env:SFA_KIT_DIR) { $env:SFA_KIT_DIR } else { Join-Path $env:TEMP 'sfa-translation-kit' }
$Installer = Join-Path $Work 'install-windows.ps1'

Write-Host ''
Write-Host 'scientific-fa-translation-skill — نصب با یک دستور' -ForegroundColor White
Write-Host "   repo: $Repo  (branch: $Branch)"


# --------------------------------------------------------------------------
Write-Host "`n== دریافت کیت" -ForegroundColor Cyan

if (Test-Path $Installer) {
  Write-Host "   [ok]   کیت از قبل هست: $Work" -ForegroundColor Green
  Write-Host '   ...    به‌روزرسانی با git pull'
  $gitCmd = Get-Command git -ErrorAction SilentlyContinue
  if ($gitCmd -and (Test-Path (Join-Path $Work '.git'))) {
    & git -C $Work pull --ff-only 2>&1 | ForEach-Object { Write-Host "   ...    $_" -ForegroundColor DarkGray }
  }
} else {
  Remove-Item -Recurse -Force $Work -ErrorAction SilentlyContinue
  $gitCmd = Get-Command git -ErrorAction SilentlyContinue
  if ($gitCmd) {
    Write-Host '   ...    git clone --depth 1'
    & git clone --depth 1 --branch $Branch "https://github.com/$Repo.git" $Work 2>&1 |
      ForEach-Object { Write-Host "   ...    $_" -ForegroundColor DarkGray }
  }
  if (-not (Test-Path $Installer)) {
    Write-Host '   ...    git نبود یا کلون نشد -> دانلود zip از GitHub'
    $zip = Join-Path $env:TEMP 'sfa-kit.zip'
    $tmp = Join-Path $env:TEMP 'sfa-kit-unzip'
    Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
    Invoke-WebRequest "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" `
      -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
    if (-not $inner) { throw 'ساختار zip نامنتظره بود' }
    New-Item -ItemType Directory -Force $Work | Out-Null
    Copy-Item (Join-Path $inner.FullName '*') $Work -Recurse -Force
    Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
  }
}
if (-not (Test-Path $Installer)) { throw "کیت دریافت نشد: $Work" }
Write-Host "   [ok]   کیت آماده است: $Work" -ForegroundColor Green

# --------------------------------------------------------------------------
$installArgs = @()
if ($Cursor)      { $installArgs += '-Cursor' }
if ($SkipTests)   { $installArgs += '-SkipTests' }
if ($SkipPoppler) { $installArgs += '-SkipPoppler' }

& $Installer @installArgs

Write-Host ''
Write-Host "   کیت در: $Work" -ForegroundColor White
Write-Host '   برای اجرای دوباره یا با گزینه‌های بیشتر، همین دستور را تکرار کنید.' -ForegroundColor Gray
