# Terminal Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the `rendek-dark` Hugo theme as a single-column terminal/editor design per `docs/superpowers/specs/2026-07-11-terminal-theme-design.md`, dropping Foundation and the sidebar, and absorbing the template-level a11y/SEO beads.

**Architecture:** All work happens inside `themes/rendek-dark/` plus small edits to `config.toml`, `content/projects.md`, and `publish.sh`. A site-output check script is written first (red), then templates/CSS are rewritten until it passes (green). No content sweeps.

**Tech Stack:** Hugo v0.157 extended, hand-written CSS (no framework), bash check script, `bd` for bead bookkeeping.

## Global Constraints

- Palette (verbatim from spec): bg `#191a2a`, surface `#212337`, panel `#2f334d`, panel-edge `#3b4066`, ink `#c8d3f5`, ink-dim `#828bb8`, lav `#b4c2f0`, green `#c3e88d`, green-dim `#a9c979`, blue `#388ED6`, blue-soft `#82aaff`, red `#E84A4A`.
- Dark-only theme; no light variant.
- Tagline text exactly: `<3 Go & Kubernetes · honeypots · homelab · leadership`.
- Exactly one `<h1>` per rendered page. `<html lang="en">` on every page.
- Mono = chrome (masthead/nav/dates/tags/footer/headings on lists); sans = body prose. System font stacks only, no webfonts.
- No `<center>`, `<nobr>`, `target="_blank"` in templates; external template links get `rel="noopener noreferrer"`.
- Decorative elements (`cursor`, status bar, `./`, `// `) must be CSS-generated or `aria-hidden="true"`.
- Commits: no Co-Authored-By trailer. Work on branch `terminal-theme`.
- Build command everywhere: `hugo --logLevel warn -d /tmp/theme-check-public` (never commit `public/`).

---

### Task 0: Branch

- [ ] **Step 1:** `git checkout -b terminal-theme` (from `master`).

---

### Task 1: Site check script (red baseline)

**Files:**
- Create: `scripts/check-site.sh`

**Interfaces:**
- Produces: `scripts/check-site.sh <publish-dir>` — exits 0 when all FAIL-level assertions pass; prints `FAIL:`/`WARN:` lines otherwise. Tasks 2–7 run it; Task 8 wires it into `publish.sh`.

- [ ] **Step 1: Write the script**

```bash
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

# 8. Optional internal link check
if command -v htmltest >/dev/null 2>&1; then
  htmltest -s "$PUB" || err "htmltest found broken internal links"
else
  warn "htmltest not installed — skipping link check (brew install htmltest)"
fi

[ "$fail" -eq 0 ] && echo "OK: all site checks passed"
exit "$fail"
```

- [ ] **Step 2: Make executable and run against current output (expect FAIL)**

Run: `chmod +x scripts/check-site.sh && hugo --logLevel warn -d /tmp/theme-check-public && scripts/check-site.sh /tmp/theme-check-public`
Expected: multiple `FAIL:` lines (brace bug, lang, h1 counts, landmarks, homepage size, foundation) and exit code 1. This is the red baseline.

- [ ] **Step 3: Commit**

```bash
git add scripts/check-site.sh
git commit -m "Add site output check script (red baseline for theme rebuild)"
```

---

### Task 2: theme.css

**Files:**
- Create: `themes/rendek-dark/static/css/theme.css`
- Modify: `themes/rendek-dark/layouts/partials/head.html` (stylesheet links only)

**Interfaces:**
- Produces: class names consumed by Tasks 3–6: `.skip`, `.page`, `.masthead`, `.site-title`, `.brace`, `.cursor`, `.tagline`, `.heart`, `.site-nav`, `.post-entry`, `.entry-title`, `.entry-summary`, `.date`, `.readmore`, `.tagrow`, `.post`, `.post-title`, `.content`, `.list-title`, `.year`, `.content-list`, `.content-item`, `.item-date`, `.terms`, `.pagination`, `.page-count`, `.site-footer`, `.footer-links`, `.statusbar`, `.sb-mode`, `.sb-file`, `.sb-pos`, `.err-404`.

- [ ] **Step 1: Write `theme.css`** (complete file)

```css
/* rendek-dark · terminal theme
   spec: docs/superpowers/specs/2026-07-11-terminal-theme-design.md */

:root {
  --bg:         #191a2a;
  --surface:    #212337;
  --panel:      #2f334d;
  --panel-edge: #3b4066;
  --ink:        #c8d3f5;
  --ink-dim:    #828bb8;
  --lav:        #b4c2f0;
  --green:      #c3e88d;
  --green-dim:  #a9c979;
  --blue:       #388ED6;
  --blue-soft:  #82aaff;
  --red:        #E84A4A;
  --mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, monospace;
  --sans: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
}

* { box-sizing: border-box; }
html { background: var(--bg); }
body {
  margin: 0;
  background: var(--bg);
  color: var(--ink);
  font-family: var(--mono);
  font-size: 16px;
  line-height: 1.6;
}
.page {
  max-width: 84ch;
  margin: 0 auto;
  padding: 32px 20px 48px;
}

a { color: var(--green); }
a:hover { color: var(--green-dim); }
:focus-visible { outline: 2px solid var(--green); outline-offset: 2px; }

.skip {
  position: absolute;
  left: -9999px;
  background: var(--green);
  color: var(--bg);
  padding: 8px 16px;
  font-family: var(--mono);
}
.skip:focus { left: 12px; top: 12px; z-index: 10; }

/* ---------- masthead ---------- */
.masthead { margin-bottom: 34px; }
.site-title {
  font-size: 26px;
  font-weight: 700;
  margin: 0 0 2px;
}
.site-title a { color: var(--lav); text-decoration: none; }
.site-title .brace { color: var(--green); }
.cursor {
  display: inline-block;
  width: 11px;
  height: 22px;
  background: var(--green);
  vertical-align: -3px;
  margin-left: 6px;
  animation: blink 1.1s steps(1) infinite;
}
@keyframes blink { 50% { opacity: 0; } }
@media (prefers-reduced-motion: reduce) { .cursor { animation: none; } }
.tagline { color: var(--ink-dim); font-size: 13px; margin: 0 0 22px; }
.tagline .heart { color: var(--red); letter-spacing: -2px; }

.site-nav {
  display: flex;
  gap: 22px;
  flex-wrap: wrap;
  font-size: 13.5px;
  border-top: 1px dashed var(--panel-edge);
  border-bottom: 1px dashed var(--panel-edge);
  padding: 12px 2px;
}
.site-nav a { color: var(--ink); text-decoration: none; text-transform: lowercase; }
.site-nav a::before { content: "./"; color: var(--ink-dim); }
.site-nav a:hover { color: var(--green); }

main { display: block; margin-top: 34px; }

/* ---------- post list (home) ---------- */
.post-entry {
  max-width: 72ch;
  margin-bottom: 36px;
  padding-left: 18px;
  border-left: 2px solid var(--panel);
}
.post-entry:hover, .post-entry:focus-within { border-left-color: var(--green); }
.date { color: var(--ink-dim); font-size: 12.5px; margin: 0; }
.date::before { content: "// "; }
.entry-title { font-size: 19px; line-height: 1.35; margin: 4px 0 10px; }
.entry-title a { color: var(--green); text-decoration: none; }
.entry-title a:hover { background: var(--green); color: var(--bg); }
.entry-summary { font-family: var(--sans); font-size: 15px; line-height: 1.65; }
.entry-summary p { margin: 0 0 12px; }
.readmore { margin: 0; font-size: 13px; }
.readmore a { color: var(--blue-soft); text-decoration: none; }
.readmore a::after { content: " →"; }
.readmore a:hover { text-decoration: underline; }
.tagrow { font-size: 12.5px; color: var(--ink-dim); margin: 8px 0 0; }
.tagrow a { color: var(--blue-soft); text-decoration: none; }
.tagrow a:hover { text-decoration: underline; }

/* ---------- single post ---------- */
.post { max-width: 72ch; }
.post-title {
  font-size: 24px;
  line-height: 1.3;
  color: var(--green);
  margin: 0 0 4px;
}
.post .content {
  font-family: var(--sans);
  font-size: 16.5px;
  line-height: 1.7;
  margin-top: 22px;
}
.post .content h2, .post .content h3, .post .content h4 {
  font-family: var(--mono);
  color: var(--lav);
  line-height: 1.3;
  margin: 1.6em 0 .5em;
}
.post .content h2 { font-size: 20px; }
.post .content h3 { font-size: 17px; }
.post .content h4 { font-size: 15.5px; }
.post .content img { max-width: 100%; height: auto; display: block; margin: 1.5em auto; }

/* code */
code { font-family: var(--mono); font-size: .92em; background: var(--surface); padding: 1px 5px; border-radius: 3px; }
pre, .highlight pre {
  background: var(--surface);
  border: 1px solid var(--panel-edge);
  border-radius: 6px;
  padding: 14px 16px;
  overflow-x: auto;
  font-size: 13px;
  line-height: 1.65;
}
pre code { background: none; padding: 0; }
.highlight { margin: 0 0 20px; }
.highlight .ln { color: var(--ink-dim); margin-right: 10px; user-select: none; }

/* tables (fixes blog-0ef) */
table { border-collapse: collapse; margin: 1.2em 0; font-size: .95em; display: block; overflow-x: auto; }
th { background: var(--panel); text-align: left; }
th, td { border: 1px solid var(--panel-edge); padding: 6px 12px; }
tr:hover td { background: var(--surface); }

blockquote {
  background: var(--surface);
  border-left: 3px solid var(--green);
  margin: 1.5em 0;
  padding: .6em 14px;
}
blockquote p { margin: .3em 0; }

hr { border: 0; border-top: 1px dashed var(--panel-edge); margin: 2em 0; }

/* ---------- list / archive / terms ---------- */
.list-title { font-size: 22px; color: var(--lav); margin: 0 0 20px; }
.year { font-size: 16px; color: var(--blue-soft); margin: 26px 0 10px; }
.content-item { display: flex; gap: 14px; margin-bottom: 6px; font-size: 14px; }
.content-item .item-date { color: var(--ink-dim); flex: none; }
.content-item a { color: var(--ink); text-decoration: none; }
.content-item a:hover { color: var(--green); }
.terms { list-style: none; padding: 0; font-size: 14.5px; }
.terms li { margin-bottom: 8px; }

/* ---------- pagination ---------- */
.pagination {
  display: flex;
  gap: 18px;
  align-items: baseline;
  font-size: 13.5px;
  margin: 40px 0 0;
}
.pagination a { color: var(--blue-soft); text-decoration: none; }
.pagination a:hover { text-decoration: underline; }
.page-count { color: var(--ink-dim); }

/* ---------- footer ---------- */
.site-footer { margin-top: 56px; }
.footer-links {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  font-size: 12.5px;
  color: var(--ink-dim);
  margin-bottom: 14px;
}
.footer-links a { color: var(--ink-dim); }
.footer-links a:hover { color: var(--green); }
.statusbar { display: flex; font-size: 12px; border-radius: 4px; overflow: hidden; }
.statusbar span { padding: 5px 14px; white-space: nowrap; }
.sb-mode { background: var(--green); color: var(--bg); font-weight: 700; }
.sb-file { background: var(--panel); color: var(--ink); flex: 1; overflow: hidden; text-overflow: ellipsis; }
.sb-pos { background: var(--blue); color: #fff; }

/* ---------- 404 ---------- */
.err-404 h1 { color: var(--green); }
```

- [ ] **Step 2: Swap stylesheet links in `head.html`**

Replace the four `<link rel="stylesheet" ...>` lines (foundation.min.css, colors.css, layout.css, pygments2.css) with:

```html
  <link rel="stylesheet" type="text/css" href="/css/theme.css" />
  <link rel="stylesheet" type="text/css" href="/css/pygments2.css" />
```

- [ ] **Step 3: Build**

Run: `hugo --logLevel warn -d /tmp/theme-check-public && grep -c 'theme.css' /tmp/theme-check-public/index.html`
Expected: build exit 0; grep prints `1`. (Site looks unstyled/odd until Tasks 3–6 land — expected mid-flight state on the branch.)

- [ ] **Step 4: Commit**

```bash
git add themes/rendek-dark/static/css/theme.css themes/rendek-dark/layouts/partials/head.html
git commit -m "Add terminal theme stylesheet, drop Foundation from head"
```

---

### Task 3: Page skeleton — header, footer, nav, render-link hook

**Files:**
- Modify: `themes/rendek-dark/layouts/partials/header.html` (full rewrite)
- Modify: `themes/rendek-dark/layouts/partials/footer.html` (full rewrite)
- Create: `themes/rendek-dark/layouts/_default/_markup/render-link.html`
- Modify: `config.toml` (remove Tech Docs menu entry)

**Interfaces:**
- Consumes: `theme.css` classes from Task 2.
- Produces: `partial "header.html"` opens `<!DOCTYPE html>…<main id="main">`; `partial "footer.html"` closes `</main>…</html>`. All page templates in Tasks 4–6 rely on this pairing.

- [ ] **Step 1: Rewrite `header.html`** (complete file)

```html
<!DOCTYPE html>
<html lang="en">
{{ partial "head.html" . }}
<body>
  <a class="skip" href="#main">Skip to content</a>
  <div class="page">
    <header class="masthead">
      {{ if .IsHome }}<h1 class="site-title">{{ else }}<p class="site-title">{{ end }}<a href="{{ .Site.BaseURL }}"><span class="brace">{</span> {{ .Site.Title }} <span class="brace">}</span></a><span class="cursor" aria-hidden="true"></span>{{ if .IsHome }}</h1>{{ else }}</p>{{ end }}
      <p class="tagline"><span class="heart">&lt;3</span> Go &amp; Kubernetes &middot; honeypots &middot; homelab &middot; leadership</p>
      <nav class="site-nav" aria-label="Main">
        {{ range .Site.Menus.main }}
        <a href="{{ .URL }}"{{ if hasPrefix .URL "http" }} rel="noopener noreferrer"{{ end }}>{{ .Name }}</a>
        {{ end }}
      </nav>
    </header>
    <main id="main">
```

- [ ] **Step 2: Rewrite `footer.html`** (complete file)

```html
    </main>
    <footer class="site-footer">
      <div class="footer-links">
        <a href="{{ "/index.xml" | absURL }}">RSS</a>
        <a href="https://github.com/joshrendek/" rel="noopener noreferrer">GitHub</a>
        <span class="copyright">{{ .Site.Copyright }}</span>
      </div>
      <div class="statusbar" aria-hidden="true">
        <span class="sb-mode">NORMAL</span>
        <span class="sb-file">~/blog{{ .RelPermalink }}</span>
        <span class="sb-pos">{{ if .IsHome }}{{ with .Paginator }}{{ .PageNumber }}/{{ .TotalPages }}{{ end }}{{ else }}&#9776; 100%{{ end }}</span>
      </div>
    </footer>
  </div>
</body>
</html>
```

- [ ] **Step 3: Create `render-link.html`** (auto-noopener for external markdown links)

```html
<a href="{{ .Destination | safeURL }}"{{ if or (hasPrefix .Destination "http://") (hasPrefix .Destination "https://") }} rel="noopener noreferrer"{{ end }}>{{ .Text | safeHTML }}</a>
```

- [ ] **Step 4: Remove the dead docs menu entry from `config.toml`** (bead blog-eiz)

Delete these lines:

```toml
[[menu.main]]
    name = "Tech Docs"
    url = "/docs/"
    weight = 2
```

- [ ] **Step 5: Build and check skeleton assertions**

Run: `hugo --logLevel warn -d /tmp/theme-check-public && for f in index.html 404.html; do grep -q '<html lang="en">' /tmp/theme-check-public/$f && grep -q 'class="skip"' /tmp/theme-check-public/$f && grep -q '<main id="main">' /tmp/theme-check-public/$f && echo "$f ok"; done`
Expected: `index.html ok` and `404.html ok`. Also `grep -rc 'Tech Docs' /tmp/theme-check-public/index.html` prints `0`.

- [ ] **Step 6: Commit**

```bash
git add themes/rendek-dark/layouts/partials/header.html themes/rendek-dark/layouts/partials/footer.html themes/rendek-dark/layouts/_default/_markup/render-link.html config.toml
git commit -m "Terminal skeleton: lang, skip link, landmarks, masthead, statusbar footer"
```

---

### Task 4: Homepage — summaries, tags, pagination

**Files:**
- Modify: `themes/rendek-dark/layouts/index.html` (full rewrite)
- Modify: `themes/rendek-dark/layouts/_default/summary.html` (full rewrite)
- Modify: `themes/rendek-dark/layouts/partials/tags.html` (full rewrite)
- Modify: `themes/rendek-dark/layouts/partials/paginator-menu.html` (full rewrite)

**Interfaces:**
- Consumes: header/footer pairing (Task 3), `theme.css` classes (Task 2).
- Produces: `{{ .Render "summary" }}` markup used only here; `partial "tags.html"` also consumed by Task 5's postfooter.

- [ ] **Step 1: Rewrite `index.html`**

```html
{{ partial "header.html" . }}
{{ $paginator := .Paginate (where .Site.RegularPages "Type" "post") }}
{{ range $paginator.Pages }}
{{ .Render "summary" }}
{{ end }}
{{ partial "paginator-menu.html" . }}
{{ partial "footer.html" . }}
```

- [ ] **Step 2: Rewrite `summary.html`**

```html
<article class="post-entry">
  <p class="date">{{ .Date.Format "Jan 2, 2006" }} &middot; {{ .ReadingTime }} min</p>
  <h2 class="entry-title"><a href="{{ .RelPermalink }}">{{ .Title }}</a></h2>
  <div class="entry-summary">{{ .Summary }}</div>
  <p class="readmore"><a href="{{ .RelPermalink }}" aria-label="Read more: {{ .Title }}">read more</a></p>
  {{ partial "tags.html" . }}
</article>
```

- [ ] **Step 3: Rewrite `tags.html`**

```html
{{ with .Params.tags }}
<p class="tagrow">tags: {{ range $i, $t := . }}{{ if $i }}, {{ end }}<a href="/tags/{{ $t | urlize }}">{{ $t }}</a>{{ end }}</p>
{{ end }}
```

- [ ] **Step 4: Rewrite `paginator-menu.html`** (bead blog-yr9)

```html
{{ if or .Paginator.HasPrev .Paginator.HasNext }}
<nav class="pagination" aria-label="Pagination">
  {{ if .Paginator.HasPrev }}<a href="{{ .Paginator.Prev.URL }}">&larr; newer</a>{{ end }}
  <span class="page-count">{{ .Paginator.PageNumber }}/{{ .Paginator.TotalPages }}</span>
  {{ if .Paginator.HasNext }}<a href="{{ .Paginator.Next.URL }}">older &rarr;</a>{{ end }}
</nav>
{{ end }}
```

- [ ] **Step 5: Build and verify homepage**

Run: `hugo --logLevel warn -d /tmp/theme-check-public && stat -f%z /tmp/theme-check-public/index.html && grep -c '<h1' /tmp/theme-check-public/index.html`
Expected: size well under 40960 bytes; h1 count `1`.

- [ ] **Step 6: Commit**

```bash
git add themes/rendek-dark/layouts/index.html themes/rendek-dark/layouts/_default/summary.html themes/rendek-dark/layouts/partials/tags.html themes/rendek-dark/layouts/partials/paginator-menu.html
git commit -m "Homepage: summary entries, terminal tags, accessible pagination"
```

---

### Task 5: Post page

**Files:**
- Modify: `themes/rendek-dark/layouts/_default/single.html` (full rewrite)
- (unchanged: `partials/postfooter.html`, `partials/disqus.html` — they already work)

**Interfaces:**
- Consumes: header/footer pairing, `tags.html` (via postfooter), `.post`/`.post-title`/`.date`/`.content` classes.

- [ ] **Step 1: Rewrite `single.html`**

```html
{{ partial "header.html" . }}
<article class="post">
  <header>
    <h1 class="post-title">{{ .Title }}</h1>
    <p class="date">{{ .Date.Format "Jan 2, 2006" }} &middot; {{ .ReadingTime }} min</p>
  </header>
  <div class="content">{{ .Content }}</div>
  {{ partial "postfooter.html" . }}
</article>
{{ partial "footer.html" . }}
```

- [ ] **Step 2: Build and verify a post page**

Run: `hugo --logLevel warn -d /tmp/theme-check-public && P=$(find /tmp/theme-check-public -path '*/2024/*' -name index.html | head -1) && grep -c '<h1' "$P" && grep -q 'disqus' "$P" && echo "disqus ok"`
Expected: h1 count `1`; `disqus ok`.

- [ ] **Step 3: Commit**

```bash
git add themes/rendek-dark/layouts/_default/single.html
git commit -m "Post page: single h1, terminal header, sans body"
```

---

### Task 6: List, archive, terms, 404 pages

**Files:**
- Modify: `themes/rendek-dark/layouts/_default/list.html` (full rewrite — fixes blog-ekf)
- Modify: `themes/rendek-dark/layouts/_default/_index.html` (full rewrite — fixes blog-ekf)
- Modify: `themes/rendek-dark/layouts/_default/li.html` (full rewrite)
- Modify: `themes/rendek-dark/layouts/_default/terms.html` (full rewrite)
- Modify: `themes/rendek-dark/layouts/archive/single.html` (full rewrite)
- Modify: `themes/rendek-dark/layouts/404.html` (full rewrite)

**Interfaces:**
- Consumes: header/footer pairing; `.list-title`/`.year`/`.content-item`/`.terms` classes.
- Produces: `li.html` render template consumed by list/archive templates via `{{ .Render "li" }}`.

- [ ] **Step 1: Rewrite `list.html`** (identical content goes in `_index.html`)

```html
{{ partial "header.html" . }}
<h1 class="list-title">{{ .Title }}</h1>
<div class="content-list">
  {{ range .Pages.GroupByDate "2006" }}
  <h2 class="year">{{ .Key }}</h2>
  {{ range .Pages }}{{ .Render "li" }}{{ end }}
  {{ end }}
</div>
{{ partial "footer.html" . }}
```

- [ ] **Step 2: Copy the same content into `_default/_index.html`** (byte-identical to Step 1's file).

- [ ] **Step 3: Rewrite `li.html`**

```html
<div class="content-item">
  <span class="item-date">{{ .Date.Format "2006-01-02" }}</span>
  <a href="{{ .RelPermalink }}">{{ .Title }}</a>
</div>
```

- [ ] **Step 4: Rewrite `terms.html`**

```html
{{ partial "header.html" . }}
<h1 class="list-title">{{ .Title }}</h1>
<ul class="terms">
  {{ range .Data.Terms.Alphabetical }}
  <li><a href="{{ .Page.RelPermalink }}">{{ .Page.Title }}</a> ({{ .Count }})</li>
  {{ end }}
</ul>
{{ partial "footer.html" . }}
```

- [ ] **Step 5: Rewrite `archive/single.html`**

```html
{{ partial "header.html" . }}
<h1 class="list-title">{{ .Title }}</h1>
<div class="content-list">
  {{ range (where .Site.RegularPages "Type" "post").GroupByDate "2006" }}
  <h2 class="year">{{ .Key }}</h2>
  {{ range .Pages }}{{ .Render "li" }}{{ end }}
  {{ end }}
</div>
{{ partial "footer.html" . }}
```

- [ ] **Step 6: Rewrite `404.html`**

```html
{{ partial "header.html" . }}
<div class="err-404">
  <h1>404 &mdash; file not found :(</h1>
  <p><a href="/">cd ~</a></p>
</div>
{{ partial "footer.html" . }}
```

- [ ] **Step 7: Build and verify list pages**

Run: `hugo --logLevel warn -d /tmp/theme-check-public && grep -rl '{ partial' /tmp/theme-check-public --include='*.html' | wc -l && C=$(find /tmp/theme-check-public/categories -mindepth 2 -name index.html | head -1) && grep -c '<h1' "$C" && head -1 "$C"`
Expected: `0` broken files; category page h1 count `1`; first line `<!DOCTYPE html>`.

- [ ] **Step 8: Commit**

```bash
git add themes/rendek-dark/layouts/_default/list.html themes/rendek-dark/layouts/_default/_index.html themes/rendek-dark/layouts/_default/li.html themes/rendek-dark/layouts/_default/terms.html themes/rendek-dark/layouts/archive/single.html themes/rendek-dark/layouts/404.html
git commit -m "Rewrite list/archive/terms/404 templates (fixes brace bug)"
```

---

### Task 7: Deletions and content merge

**Files:**
- Delete: `themes/rendek-dark/layouts/partials/sidebar.html`, `themes/rendek-dark/layouts/partials/social-links.html`, `themes/rendek-dark/layouts/partials/social-links-footer.html`
- Delete: `themes/rendek-dark/static/css/foundation.min.css`, `themes/rendek-dark/static/css/colors.css`, `themes/rendek-dark/static/css/layout.css`
- Modify: `content/projects.md` (add "Elsewhere" section; demote inline h1/h2s)

**Interfaces:**
- Consumes: nothing may reference the deleted partials — Tasks 3–6 already removed every `partial "sidebar.html"` / `social-links` call site.

- [ ] **Step 1: Verify nothing references the doomed files, then delete**

Run: `grep -rl 'sidebar.html\|social-links' themes/rendek-dark/layouts --include='*.html' | grep -v 'partials/sidebar\|partials/social-links'`
Expected: no output. Then:

```bash
git rm themes/rendek-dark/layouts/partials/sidebar.html themes/rendek-dark/layouts/partials/social-links.html themes/rendek-dark/layouts/partials/social-links-footer.html
git rm themes/rendek-dark/static/css/foundation.min.css themes/rendek-dark/static/css/colors.css themes/rendek-dark/static/css/layout.css
```

Also resolve the already-deleted docs layouts sitting in git status: `git rm themes/rendek-dark/layouts/docs/docs.html themes/rendek-dark/layouts/docs/li.html` (they were deleted on disk previously; this stages the deletion).

- [ ] **Step 2: Update `content/projects.md`** — the sidebar's project links (threat.gg/threatwar, garden.gg, ifcfg.net) are already on this page. Make two edits: (a) change the raw `<h1>Maintained</h1>` and `<h1>Unmaintained</h1>` to `## Maintained` / `## Unmaintained`, and delete the duplicate `<hr>` + `<h2>Unmaintained</h2>` pair; (b) append the sidebar's "Other Blogs" content at the end:

```markdown
## Elsewhere

* [Tender Meat Love](http://tendermeatlove.com)
  * my blog about cooking
```

- [ ] **Step 3: Build and verify**

Run: `hugo --logLevel warn -d /tmp/theme-check-public && grep -rl 'foundation.min.css' /tmp/theme-check-public --include='*.html' | wc -l && grep -c '<h1' /tmp/theme-check-public/projects/index.html`
Expected: `0` foundation references; projects page h1 count `1`.

- [ ] **Step 4: Commit**

```bash
git add content/projects.md
git commit -m "Remove sidebar, social-links partials and Foundation CSS; fold sidebar content into projects page"
```

---

### Task 8: Green gate, publish wiring, bead bookkeeping

**Files:**
- Modify: `publish.sh`

**Interfaces:**
- Consumes: `scripts/check-site.sh` (Task 1).

- [ ] **Step 1: Full check run**

Run: `hugo --logLevel warn -d /tmp/theme-check-public && scripts/check-site.sh /tmp/theme-check-public`
Expected: `OK: all site checks passed`, exit 0 (WARNs allowed for content-level `target="_blank"` and missing htmltest). If anything FAILs, fix the responsible template before proceeding.

- [ ] **Step 2: Wire the gate into `publish.sh`** (full new content)

```bash
#!/bin/bash
set -euo pipefail
hugo --logLevel warn
scripts/check-site.sh public
rsync -avz --delete --exclude=docs public/ www-data@static-sites:html/
```

- [ ] **Step 3: Visual pass**

Run: `hugo server -D` and check in a browser (or via the browse/qa skill): homepage, one long code-heavy post (e.g. the VictoriaLogs post), a category page, /archives/, /projects/, /404.html. Verify: blinking cursor pauses under reduced motion (macOS: System Settings → Accessibility → Display → Reduce motion), tables readable, code blocks scroll horizontally on narrow viewport, skip link appears on first Tab press.

- [ ] **Step 4: Commit publish.sh**

```bash
git add publish.sh
git commit -m "Gate publish on site checks"
```

- [ ] **Step 5: Close absorbed beads**

```bash
bd close blog-ekf blog-7l8 blog-deo blog-11k blog-0ef blog-yr9 blog-syu blog-eiz --reason "Fixed by terminal theme rebuild (branch terminal-theme)"
bd comment blog-0ra "Template-level instances fixed by theme rebuild + render-link hook; remaining instances are raw HTML in old post content."
```

(If `bd close` doesn't accept multiple IDs or `--reason`, check `bd close --help` and adapt; `bd comment` may be `bd update --append-notes`.)

- [ ] **Step 6: Merge decision** — use superpowers:finishing-a-development-branch (merge `terminal-theme` → `master`, then deploy manually with `./publish.sh` when ready).

---

## Out of scope (unchanged beads)

Content-level and head-SEO beads remain open and are NOT addressed here: blog-6f2 (alt text), blog-n1d (meta descriptions), blog-s71 (categories), blog-ya1 (canonical/RSS link), blog-0n0 (robots.txt), blog-naf (og:image), blog-2r5 (title format), blog-4hk (config cleanup).
