#!/usr/bin/env bash
# lint + build the RTL PDF with --verify, then report pages, fonts and the sidecar.
# Self-locating: works from any folder, on any machine.
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SK="${SK:-$HOME/.cline/skills/scientific-fa-translation-skill}"
SLUG="${SLUG:-shahzade-kuchak-fasl-1-2}"
OUT="${OUT:-$HOME/Documents/books}"

bash "$SK/scripts/build-pdf.sh" "$W/doc.html" "$SLUG" --verify
echo "build exit=$?"

echo
echo '===== artifacts ====='
ls -la "$OUT/$SLUG".* 2>&1

echo
echo '===== pages / fonts ====='
pdfinfo "$OUT/$SLUG.pdf" 2>/dev/null | grep -iE 'pages|page size'
pdffonts "$OUT/$SLUG.pdf" 2>/dev/null

echo
echo '===== .txt sidecar, first 12 lines ====='
head -12 "$OUT/$SLUG.txt" 2>&1

echo
echo '===== Persian characters in the sidecar ====='
python3 - "$OUT/$SLUG.txt" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding='utf-8').read()
print('Persian chars:', len(re.findall(r'[\u0600-\u06FF]', text)),
      '| total chars:', len(text))
PY
