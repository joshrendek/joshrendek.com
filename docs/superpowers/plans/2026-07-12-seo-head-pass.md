# SEO Head Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close beads blog-ya1, blog-0n0, blog-n1d, blog-2r5, blog-naf, blog-4hk — canonical URLs, RSS alternate link, per-page meta descriptions, title format, robots.txt, default og:image, and dead-config cleanup.

**Architecture:** Extend `scripts/check-site.sh` first (red), then rework `head.html` + two new partials, enable robots.txt, add the og:image asset (controller supplies the PNG), and finish with config cleanup verified by output diffing. Branch: `seo-head-pass`.

**Tech Stack:** Hugo v0.157 extended, bash gate script.

## Global Constraints

- Site: https://joshrendek.com (root baseURL). Site-wide description fallback: `Josh Rendek's blog on software engineering, Go, Ruby, infrastructure, and security.`
- Title format: homepage → `Josh Rendek`; every other page → `{{ .Title }} | Josh Rendek`, on ONE line, no padding whitespace.
- Descriptions: page `.Description` front matter wins; else posts use `.Summary | plainify | chomp | truncate 155`; else site default.
- Keep `_internal/opengraph.html` + `_internal/twitter_cards.html`; REMOVE `_internal/schema.html` (deprecated) in favor of JSON-LD.
- Build command: `hugo --logLevel warn -d /tmp/theme-check-public` (exit 0, zero warnings).
- Commits: no Co-Authored-By trailer. Branch `seo-head-pass`.

---

### Task 1: Extend check-site.sh (red baseline)

**Files:**
- Modify: `scripts/check-site.sh`

**Interfaces:**
- Produces: new FAIL assertions consumed as the done-definition by Tasks 2–4.

- [ ] **Step 1:** Append this block to `scripts/check-site.sh` immediately BEFORE the final `# 8. Optional internal link check` section:

```bash
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
```

- [ ] **Step 2:** Run `hugo --logLevel warn -d /tmp/theme-check-public && scripts/check-site.sh /tmp/theme-check-public`.
Expected: FAILs for canonical, RSS alternate, robots.txt, og:image, title suffix, site-wide description. Exit 1. Record all FAIL lines.

- [ ] **Step 3:** Commit:
```bash
git add scripts/check-site.sh
git commit -m "Extend site gate with SEO head assertions (red baseline)"
```

---

### Task 2: head.html rework — canonical, RSS, descriptions, titles, JSON-LD

**Files:**
- Modify: `themes/rendek-dark/layouts/partials/head.html` (full rewrite)
- Create: `themes/rendek-dark/layouts/partials/page-description.html`
- Create: `themes/rendek-dark/layouts/partials/structured-data.html`

**Interfaces:**
- Produces: `partial "page-description.html"` returns a plain-text description string; consumed by head.html and structured-data.html.

- [ ] **Step 1:** Create `page-description.html` (single line, no trailing newline output):

```
{{- if .Description -}}{{ .Description }}{{- else if and .IsPage .Summary -}}{{ .Summary | plainify | chomp | truncate 155 }}{{- else -}}{{ .Site.Params.meta.description }}{{- end -}}
```

- [ ] **Step 2:** Create `structured-data.html`:

```html
{{ if .IsPage }}
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": {{ .Title | jsonify }},
  "url": {{ .Permalink | jsonify }},
  "datePublished": {{ .Date.Format "2006-01-02T15:04:05Z07:00" | jsonify }},
  "dateModified": {{ .Lastmod.Format "2006-01-02T15:04:05Z07:00" | jsonify }},
  "author": { "@type": "Person", "name": {{ .Site.Params.author | jsonify }} },
  "description": {{ partial "page-description.html" . | jsonify }}
}
</script>
{{ else if .IsHome }}
<script type="application/ld+json">
{ "@context": "https://schema.org", "@type": "WebSite", "name": {{ .Site.Title | jsonify }}, "url": {{ .Site.BaseURL | jsonify }} }
</script>
{{ end }}
```

- [ ] **Step 3:** Rewrite `head.html` (complete file):

```html
<head>
  <meta charset="utf-8" />
  <meta name="author" content="{{ .Site.Params.author }}" />
  <meta name="description" content="{{ partial "page-description.html" . }}" />
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link rel="canonical" href="{{ .Permalink }}" />
  <link rel="alternate" type="application/rss+xml" href="{{ "index.xml" | absURL }}" title="{{ .Site.Title }}" />
  {{ template "_internal/opengraph.html" . }}
  {{ template "_internal/twitter_cards.html" . }}
  {{ partial "structured-data.html" . }}
  <link rel="stylesheet" type="text/css" href="/css/theme.css" />
  <link rel="stylesheet" type="text/css" href="/css/pygments2.css" />
  <link rel="icon" type="image/x-icon" href="/favicon.ico">
  <title>{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} | {{ .Site.Title }}{{ end }}</title>
</head>
```

Removed vs old file: `meta keywords` (obsolete — bead blog-4hk), `_internal/schema.html` (deprecated), `?123` favicon cache-buster, whitespace-padded multi-line title.

- [ ] **Step 4:** Build and verify: canonical + RSS link + one-line suffixed title on a post page; JSON-LD `BlogPosting` present on a post, `WebSite` on homepage; post meta description differs from site default and is ≤ ~160 chars; no `name="keywords"` and no `itemprop=` schema meta remain in output.

- [ ] **Step 5:** Commit:
```bash
git add themes/rendek-dark/layouts/partials/head.html themes/rendek-dark/layouts/partials/page-description.html themes/rendek-dark/layouts/partials/structured-data.html
git commit -m "SEO head: canonical, RSS alternate, per-page descriptions, title suffix, JSON-LD"
```

---

### Task 3: robots.txt

**Files:**
- Modify: `config.toml` (`enableRobotsTXT = false` → `true`)
- Create: `layouts/robots.txt` (project-level, not theme)

- [ ] **Step 1:** `layouts/robots.txt`:

```
User-agent: *
Allow: /

Sitemap: {{ "sitemap.xml" | absURL }}
```

- [ ] **Step 2:** Flip `enableRobotsTXT = true` in config.toml.
- [ ] **Step 3:** Build; verify `/tmp/theme-check-public/robots.txt` contains `Sitemap: https://joshrendek.com/sitemap.xml`.
- [ ] **Step 4:** Commit:
```bash
git add config.toml layouts/robots.txt
git commit -m "Enable robots.txt with sitemap reference"
```

---

### Task 4: default og:image

**Files:**
- Add: `static/images/og-default.png` (1200×630 — supplied by controller before dispatch; do NOT generate)
- Modify: `config.toml` (add `images = ["/images/og-default.png"]` under `[params]`)

- [ ] **Step 1:** Confirm `static/images/og-default.png` exists (controller placed it).
- [ ] **Step 2:** Add under the existing `[params]` section: `images = ["/images/og-default.png"]`.
- [ ] **Step 3:** Build; verify homepage AND a post page emit `<meta property="og:image" content="https://joshrendek.com/images/og-default.png">` and a `twitter:image` meta; twitter card should switch to `summary_large_image`. If Hugo's internal templates do not fall back to site params for either tag, report BLOCKED with the rendered head — do not hand-add meta tags without controller sign-off.
- [ ] **Step 4:** Commit:
```bash
git add static/images/og-default.png config.toml
git commit -m "Add default og:image for social shares"
```

---

### Task 5: config cleanup

**Files:**
- Modify: `config.toml`

- [ ] **Step 1:** Baseline: build to `/tmp/before-cleanup` and save `cp /tmp/before-cleanup/index.html /tmp/before-home.html` plus one post page.
- [ ] **Step 2:** Edits to config.toml:
  - Delete `googleAnalytics = "UA-3754808-1"` (dead Universal Analytics; never rendered).
  - Delete `keywords` line from `[params.meta]` (no longer consumed).
  - Replace `paginate = 10` / `paginatePath = "page"` with:
    ```toml
    [pagination]
    pagerSize = 10
    path = "page"
    ```
  - Delete the `pygments*` keys (`pygmentsCodefences`, `pygmentsCodeFencesGuessSyntax`, `pygmentsOptions`, `pygmentsStyle`, `pygmentsUseClasses`) and `highlighter = "chroma"`; add:
    ```toml
    [markup.highlight]
    codeFences = true
    guessSyntax = true
    noClasses = false
    lineNos = true
    lineNumbersInTable = false
    ```
  - Delete plainly dead keys: `watch`, `log`, `verbose`, `verboseLog`, `stepAnalysis`, `defaultExtension`, `newContentEditor`, `source`, `config`.
- [ ] **Step 3:** Build to `/tmp/theme-check-public`; diff homepage and the same post page against the Step 1 copies. Allowed differences: NONE on homepage; code-block line-number markup MAY differ slightly on the post — if it does, paste the diff hunks in the report for controller review. Pagination must still yield the same page count.
- [ ] **Step 4:** Full gate: `scripts/check-site.sh /tmp/theme-check-public` → `OK: all site checks passed`.
- [ ] **Step 5:** Commit:
```bash
git add config.toml
git commit -m "Config cleanup: drop dead UA analytics, keywords, legacy Hugo keys"
```

---

### Task 6 (controller): gate, beads, review, merge

- [ ] Full gate green; deploy NOT run (user publishes).
- [ ] `bd close blog-ya1 blog-0n0 blog-n1d blog-2r5 blog-naf blog-4hk --reason "Fixed by seo-head-pass branch"`.
- [ ] Final whole-branch review (opus) over merge-base..HEAD.
- [ ] finishing-a-development-branch options.
