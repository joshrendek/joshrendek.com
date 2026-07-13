#!/usr/bin/env bash
# Verifies built site output against the terminal-theme spec
# (docs/superpowers/specs/2026-07-11-terminal-theme-design.md).
set -uo pipefail
PUB="${1:-public}"
fail=0
err()  { echo "FAIL: $*"; fail=1; }
warn() { echo "WARN: $*"; }

[ -d "$PUB" ] || { echo "FAIL: publish dir '$PUB' not found"; exit 1; }

# Sample pages: home, 404, archives, first post, first category term page
POST=$(find "$PUB" -path "$PUB/2*" -name index.html | sort | head -1)
CAT=$(find "$PUB/categories" -mindepth 2 -name index.html 2>/dev/null | sort | head -1)
SAMPLES="$PUB/index.html $PUB/404.html $PUB/archives/index.html $POST $CAT"

# 1. Brace-bug regression guard
if grep -rl --include='*.html' '{ partial' "$PUB" | grep -q .; then
  err "literal '{ partial' found in output (broken template)"
fi

# 2. lang attribute
for f in $SAMPLES; do
  grep -q '<html lang="en">' "$f" || err "missing <html lang=\"en\">: $f"
done

# 3. Exactly one h1 per sampled page
for f in $SAMPLES; do
  n=$(grep -o '<h1' "$f" | wc -l | tr -d ' ')
  [ "$n" -eq 1 ] || err "expected 1 <h1>, got $n: $f"
done

# 4. Landmarks + skip link
for f in $SAMPLES; do
  grep -q '<main' "$f" || err "missing <main>: $f"
  grep -q '<nav'  "$f" || err "missing <nav>: $f"
  grep -q 'class="skip"' "$f" || err "missing skip link: $f"
done

# 5. Homepage renders summaries, not full posts (size guard; was 88K)
size=$(stat -f%z "$PUB/index.html" 2>/dev/null || stat -c%s "$PUB/index.html")
[ "$size" -lt 40960 ] || err "homepage index.html is ${size}B (>= 40KB — full content?)"

# 6. Dead framework / deprecated markup
grep -rl --include='*.html' 'foundation.min.css' "$PUB" | grep -q . && err "foundation.min.css still referenced"
grep -rl --include='*.html' '<center>' "$PUB" | grep -q . && err "<center> found in output"
grep -rl --include='*.html' '<nobr>'   "$PUB" | grep -q . && err "<nobr> found in output"

# 7. target=_blank hygiene (WARN only: legacy raw-HTML in old posts is a
#    content fix tracked by bead blog-0ra, not a template regression)
bad=$(grep -rhoE '<a [^>]*target="_blank"[^>]*>' --include='*.html' "$PUB" | grep -cv noopener)
[ "$bad" -eq 0 ] || warn "$bad target=\"_blank\" links without rel=noopener (content-level)"

# 9. SEO head assertions (seo-head-pass)
for f in $SAMPLES; do
  grep -q 'rel="canonical"' "$f" || err "missing canonical: $f"
  grep -q 'application/rss' "$f" || err "missing RSS alternate link: $f"
done
if [ -f "$PUB/robots.txt" ]; then
  grep -q 'Sitemap: https://joshrendek.com/sitemap.xml' "$PUB/robots.txt" || err "robots.txt lacks Sitemap line"
else
  err "robots.txt missing"
fi
grep -q 'property="og:image"' "$PUB/index.html" || err "missing og:image on homepage"
if [ -n "$POST" ]; then
  grep -q '| Josh Rendek</title>' "$POST" || err "post title lacks site suffix: $POST"
  grep 'name="description"' "$POST" | grep -q 'blog on software engineering' && err "post still uses site-wide description: $POST"
fi

# 8. Optional internal link check
if command -v htmltest >/dev/null 2>&1; then
  htmltest -s "$PUB" || err "htmltest found broken internal links"
else
  warn "htmltest not installed — skipping link check (brew install htmltest)"
fi

[ "$fail" -eq 0 ] && echo "OK: all site checks passed"
exit "$fail"
