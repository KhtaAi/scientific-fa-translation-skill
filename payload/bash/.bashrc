# ساخته‌شده توسط install-windows.ps1 — محتوای واقعی در ~/.bashenv است تا
# shellهای غیرتعاملی (که $BASH_ENV را می‌خوانند و نه ~/.bashrc را) هم همان
# محیط را داشته باشند.
if [ -f "$HOME/.bashenv" ]; then
  . "$HOME/.bashenv"
fi