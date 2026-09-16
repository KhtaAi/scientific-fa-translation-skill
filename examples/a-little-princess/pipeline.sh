#!/usr/bin/env bash
# build doc.html from part-*.txt, then lint with check-fa --strict.
# Self-locating: works from any folder, on any machine.
W="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SK="${SK:-$HOME/.cline/skills/scientific-fa-translation-skill}"

echo '=== build doc.html ==='
python3 "$W/build-doc.py"

echo
echo '=== lint (check-fa --strict) ==='
python3 "$SK/scripts/check-fa.py" "$W/doc.html" \
  --level system-docs --terms "$W/terms.tsv" --manifest "$W/manifest.txt" --strict
echo "lint exit=$?"

