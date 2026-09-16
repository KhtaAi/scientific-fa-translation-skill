#!/usr/bin/env bash
# install.sh — scientific-fa-translation-skill, one-command installer
# for Linux / macOS / WSL.   Usage:  bash install.sh [--no-apt]
set -uo pipefail

WITH_APT=1
for arg in "$@"; do
  case "$arg" in
    --no-apt) WITH_APT=0 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_NAME="scientific-fa-translation-skill"
SKILLS_DIR="$HOME/.cline/skills"
SKILL_PATH="$SKILLS_DIR/$SKILL_NAME"

step() { printf '\n== %s\n' "$*"; }
ok()   { printf '   [ok]   %s\n' "$*"; }
warn() { printf '   [warn] %s\n' "$*"; }
fail() { printf '   [FAIL] %s\n' "$*"; exit 1; }

step '1. installing the skill into ~/.cline/skills'
mkdir -p "$SKILLS_DIR"
if [ -f "$HERE/skill/SKILL.md" ]; then
  rm -rf "$SKILL_PATH"
  mkdir -p "$SKILL_PATH"
  cp -R "$HERE/skill/." "$SKILL_PATH/"
  rm -rf "$SKILL_PATH/.git"
  ok "copied from the kit -> $SKILL_PATH"
elif [ -d "$SKILL_PATH/.git" ]; then
  git -C "$SKILL_PATH" pull --ff-only 2>&1 | sed 's/^/   /' || warn 'git pull failed'
  ok "updated -> $SKILL_PATH"
else
  command -v git >/dev/null 2>&1 || fail 'git not found and the kit has no skill/ folder'
  git clone --depth 1 https://github.com/isArman/scientific-fa-translation-skill.git "$SKILL_PATH"
fi
[ -f "$SKILL_PATH/SKILL.md" ] || fail 'SKILL.md missing; the install did not complete'
ok 'SKILL.md present'

step '2. system packages  (skip with --no-apt)'
if [ "$WITH_APT" -eq 1 ]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq texlive-xetex texlive-lang-arabic \
      texlive-fonts-recommended latexmk poppler-utils python3-pip \
      || warn 'apt-get reported errors; continuing'
  elif command -v brew >/dev/null 2>&1; then
    brew install poppler python3 || warn 'brew reported errors; continuing'
  else
    warn 'no apt-get / brew found — install poppler-utils by hand, and TeX for the best print output'
  fi
fi

step '3. python packages (pillow, pymupdf)'
python3 -m pip install --quiet --upgrade pillow pymupdf \
  || warn 'pip install failed (needed only for documents with figures)'
python3 -c 'import PIL.Image, pymupdf; print("   [ok]   pillow + pymupdf")' \
  || warn 'pillow/pymupdf not importable'

step '4. Vazirmatn fonts'
FONT_DEST="$SKILL_PATH/assets/fonts"
mkdir -p "$FONT_DEST"
if ls "$HERE"/payload/fonts/*.ttf >/dev/null 2>&1; then
  cp "$HERE"/payload/fonts/*.ttf "$FONT_DEST/"
  ok "copied $(ls "$HERE"/payload/fonts/*.ttf | wc -l | tr -d ' ') font file(s) to $FONT_DEST"
else
  bash "$SKILL_PATH/scripts/fetch-vazirmatn.sh" "$FONT_DEST" \
    || warn 'font fetch failed; a document needs fonts/ next to it'
fi

step '5. verify'
bash "$SKILL_PATH/scripts/preflight.sh"
echo
bash "$SKILL_PATH/tests/run.sh" 2>&1 | tail -n 6
echo
ok 'installation finished'
printf '\n   restart Cline, then use:  /%s\n\n' "$SKILL_NAME"
